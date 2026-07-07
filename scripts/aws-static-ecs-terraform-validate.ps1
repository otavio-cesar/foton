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

Push-Location $terraformDir
try {
    & $terraform fmt -recursive
    if ($LASTEXITCODE -ne 0) {
        throw "terraform fmt falhou com codigo $LASTEXITCODE."
    }

    if (Test-Path "backend.hcl") {
        & $terraform init -backend-config=backend.hcl
    }
    else {
        & $terraform init -backend=false
    }

    if ($LASTEXITCODE -ne 0) {
        throw "terraform init falhou com codigo $LASTEXITCODE."
    }

    & $terraform validate
    if ($LASTEXITCODE -ne 0) {
        throw "terraform validate falhou com codigo $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
