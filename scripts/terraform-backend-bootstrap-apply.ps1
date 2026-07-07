param(
    [string] $AwsRegion = "sa-east-1",
    [string] $ProjectName = "foton-ev",
    [string] $Environment = "prod",
    [string] $StateBucketName = "",
    [string] $LockTableName = ""
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
$terraformDir = Join-Path $repoRoot "infra\terraform-backend\bootstrap"

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
        -var "state_bucket_name=$StateBucketName" `
        -var "lock_table_name=$LockTableName"

    if ($LASTEXITCODE -ne 0) {
        throw "terraform apply falhou."
    }

    Write-Host ""
    Write-Host "Outputs para configurar backend.hcl:"
    & $terraform output backend_config_static_ecs

    $stateBucket = (& $terraform output -raw state_bucket).Trim()
    $lockTable = (& $terraform output -raw lock_table).Trim()
    $stateKey = (& $terraform output -raw static_ecs_state_key).Trim()
    $region = (& $terraform output -raw aws_region).Trim()
    $backendFile = Join-Path $repoRoot "infra\aws-static-ecs\terraform\backend.hcl"

    @(
        "bucket         = `"$stateBucket`"",
        "key            = `"$stateKey`"",
        "region         = `"$region`"",
        "dynamodb_table = `"$lockTable`"",
        "encrypt        = true"
    ) | Set-Content -Path $backendFile -Encoding ascii

    Write-Host ""
    Write-Host "backend.hcl gerado em: $backendFile"
    Write-Host "Para migrar state local existente, rode terraform init -backend-config=backend.hcl -migrate-state na stack."
}
finally {
    Pop-Location
}
