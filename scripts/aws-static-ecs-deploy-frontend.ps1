param(
    [string] $AwsRegion = "sa-east-1"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraform = Join-Path $repoRoot ".tools\terraform\terraform.exe"
$terraformDir = Join-Path $repoRoot "infra\aws-static-ecs\terraform"
$webDir = Join-Path $repoRoot "apps\web"
$distDir = Join-Path $webDir "dist\foton-landing-page\browser"
$aws = "aws"
$npm = "npm.cmd"

if (Test-Path "C:\Program Files\Amazon\AWSCLIV2\aws.exe") {
    $aws = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
}

Push-Location $webDir
try {
    & $npm ci
    if ($LASTEXITCODE -ne 0) {
        throw "npm ci falhou."
    }

    & $npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Build do Angular falhou."
    }
}
finally {
    Pop-Location
}

Push-Location $terraformDir
try {
    $frontendBucket = (& $terraform output -raw frontend_bucket).Trim()
    $distributionId = (& $terraform output -raw cloudfront_distribution_id).Trim()
}
finally {
    Pop-Location
}

if (-not (Test-Path $distDir)) {
    throw "Build Angular nao encontrado em $distDir."
}

& $aws s3 sync $distDir "s3://$frontendBucket" --delete --region $AwsRegion
if ($LASTEXITCODE -ne 0) {
    throw "aws s3 sync falhou."
}

& $aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"
if ($LASTEXITCODE -ne 0) {
    throw "Invalidacao do CloudFront falhou."
}

Write-Host "Frontend publicado em s3://$frontendBucket e CloudFront invalidado."
