output "instance_id" {
  value = aws_instance.main.id
}

output "public_ip" {
  value = aws_eip.main.public_ip
}

output "ssh_user" {
  value = "ec2-user"
}

output "private_key_path" {
  value     = try(local_sensitive_file.generated_private_key[0].filename, null)
  sensitive = true
}

output "ansible_inventory" {
  value = "${aws_eip.main.public_ip} ansible_user=ec2-user"
}
