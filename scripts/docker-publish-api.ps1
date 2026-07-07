param(
    [Parameter(Mandatory = $true)]
    [string] $DockerHubNamespace,

    [string] $Tag = "latest",
    [string] $ApiImageName = "foton-api"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$docker = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin\docker.exe"

if (-not (Test-Path $docker)) {
    $docker = "docker"
}

Push-Location $repoRoot
try {
    & $docker version
    if ($LASTEXITCODE -ne 0) {
        throw "Docker nao esta acessivel. Abra o Docker Desktop e rode docker info."
    }

    $apiImage = "$DockerHubNamespace/$ApiImageName`:$Tag"

    & $docker build -f deploy/docker/api.Dockerfile -t $apiImage .
    if ($LASTEXITCODE -ne 0) {
        throw "Build da API falhou."
    }

    & $docker push $apiImage
    if ($LASTEXITCODE -ne 0) {
        throw "Push da API falhou. Execute docker login e tente novamente."
    }

    Write-Host "Publicado: $apiImage"
}
finally {
    Pop-Location
}
