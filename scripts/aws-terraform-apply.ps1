param(
    [Parameter(Mandatory = $true)]
    [string] $DockerHubNamespace,

    [Parameter(Mandatory = $true)]
    [string] $DbPassword,

    [string] $ImageTag = "latest",
    [string] $AwsRegion = "sa-east-1",
    [string] $ProjectName = "foton-ev",
    [string] $Environment = "prod",
    [string] $DbUsername = "foton"
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
$terraformDir = Join-Path $repoRoot "infra\terraform\aws"
$gitBin = Join-Path $repoRoot ".tools\git\cmd"

if (-not (Test-Path $terraform)) {
    throw "Terraform local nao encontrado em .tools\terraform."
}

if (Test-Path $gitBin) {
    $env:PATH = "$gitBin;$env:PATH"
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
        -var "dockerhub_namespace=$DockerHubNamespace" `
        -var "image_tag=$ImageTag" `
        -var "db_username=$DbUsername" `
        -var "db_password=$DbPassword"

    if ($LASTEXITCODE -ne 0) {
        throw "terraform apply falhou."
    }
}
finally {
    Pop-Location
}
