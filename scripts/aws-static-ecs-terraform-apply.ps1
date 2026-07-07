param(
    [string] $DockerHubNamespace = "otavioc31",
    [string] $ImageTag = "latest",
    [string] $AwsRegion = "sa-east-1",
    [string] $ProjectName = "foton-ev",
    [string] $Environment = "prod"
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
$terraformDir = Join-Path $repoRoot "infra\aws-static-ecs\terraform"

if (-not (Test-Path $terraform)) {
    throw "Terraform local nao encontrado em .tools\terraform."
}

$apiImage = "$DockerHubNamespace/foton-api`:$ImageTag"

if (Test-Path (Join-Path $terraformDir "backend.hcl")) {
    & $terraform "-chdir=$terraformDir" init "-backend-config=backend.hcl"
}
else {
    throw "backend.hcl nao encontrado em infra\aws-static-ecs\terraform. Rode o bootstrap e crie o arquivo antes do apply."
}

if ($LASTEXITCODE -ne 0) {
    throw "terraform init falhou."
}

& $terraform "-chdir=$terraformDir" apply -auto-approve `
    -var "aws_region=$AwsRegion" `
    -var "project_name=$ProjectName" `
    -var "environment=$Environment" `
    -var "api_image=$apiImage"

if ($LASTEXITCODE -ne 0) {
    throw "terraform apply falhou."
}
