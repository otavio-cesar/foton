param(
    [Parameter(Mandatory = $true)]
    [string] $SshAllowedCidr,

    [string] $AwsRegion = "sa-east-1",
    [string] $ProjectName = "foton-ev",
    [string] $Environment = "prod",
    [string] $InstanceType = "t3.small"
)

$ErrorActionPreference = "Stop"

Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:ALL_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:http_proxy -ErrorAction SilentlyContinue
Remove-Item Env:https_proxy -ErrorAction SilentlyContinue
Remove-Item Env:all_proxy -ErrorAction SilentlyContinue

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraform = Join-Path $repoRoot ".tools\terraform\terraform.exe"
$terraformDir = Join-Path $repoRoot "infra\ec2-docker\terraform"

if (-not (Test-Path $terraform)) {
    throw "Terraform local nao encontrado em .tools\terraform."
}

Push-Location $terraformDir
try {
    & $terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "terraform init falhou."
    }

    & $terraform apply `
        -var "aws_region=$AwsRegion" `
        -var "project_name=$ProjectName" `
        -var "environment=$Environment" `
        -var "instance_type=$InstanceType" `
        -var "ssh_allowed_cidr=$SshAllowedCidr"

    if ($LASTEXITCODE -ne 0) {
        throw "terraform apply falhou."
    }
}
finally {
    Pop-Location
}
