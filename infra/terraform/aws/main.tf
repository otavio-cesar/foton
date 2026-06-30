locals {
  name      = "${var.project_name}-${var.environment}"
  api_image = "${var.dockerhub_namespace}/${var.api_image_name}:${var.image_tag}"
  web_image = "${var.dockerhub_namespace}/${var.web_image_name}:${var.image_tag}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = "10.42.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.42.0.0/24", "10.42.1.0/24"]
  private_subnets = ["10.42.10.0/24", "10.42.11.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = var.eks_min_size
      max_size       = var.eks_max_size
      desired_size   = var.eks_desired_size
      instance_types = var.eks_node_instance_types
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.public_subnets
    }
  }

  tags = local.tags
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Allow PostgreSQL from EKS nodes."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS node security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db"
  subnet_ids = module.vpc.private_subnets
  tags       = local.tags
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.name}-postgres"
  engine                 = "postgres"
  engine_version         = "17"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  db_name                = "foton"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = false
  storage_encrypted      = true
  tags                   = local.tags
}

resource "kubernetes_namespace" "foton" {
  metadata {
    name = "foton"
  }

  depends_on = [module.eks]
}

resource "kubernetes_secret" "foton" {
  metadata {
    name      = "foton-secrets"
    namespace = kubernetes_namespace.foton.metadata[0].name
  }

  data = {
    db-connection-string = "Host=${aws_db_instance.postgres.address};Port=5432;Database=foton;Username=${var.db_username};Password=${var.db_password};SSL Mode=Require;Trust Server Certificate=true"
  }
}

resource "kubernetes_deployment" "api" {
  metadata {
    name      = "foton-api"
    namespace = kubernetes_namespace.foton.metadata[0].name
    labels = {
      app = "foton-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "foton-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "foton-api"
        }
      }

      spec {
        container {
          name  = "api"
          image = local.api_image

          port {
            container_port = 8080
          }

          env {
            name = "ConnectionStrings__FotonDb"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.foton.metadata[0].name
                key  = "db-connection-string"
              }
            }
          }

          env {
            name  = "Database__EnsureCreatedOnStartup"
            value = "true"
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api" {
  metadata {
    name      = "foton-api"
    namespace = kubernetes_namespace.foton.metadata[0].name
  }

  spec {
    selector = {
      app = "foton-api"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "web" {
  metadata {
    name      = "foton-web"
    namespace = kubernetes_namespace.foton.metadata[0].name
    labels = {
      app = "foton-web"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "foton-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "foton-web"
        }
      }

      spec {
        container {
          name  = "web"
          image = local.web_image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "web" {
  metadata {
    name      = "foton-web"
    namespace = kubernetes_namespace.foton.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "foton-web"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}
