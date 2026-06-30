$ErrorActionPreference = "Stop"

Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:ALL_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:http_proxy -ErrorAction SilentlyContinue
Remove-Item Env:https_proxy -ErrorAction SilentlyContinue
Remove-Item Env:all_proxy -ErrorAction SilentlyContinue

$repoRoot = Split-Path -Parent $PSScriptRoot
$dotnet = Join-Path $repoRoot ".tools\dotnet\dotnet.exe"

if (-not (Test-Path $dotnet)) {
    throw "SDK .NET local nao encontrado em .tools\dotnet. Execute a instalacao do SDK antes."
}

$env:DOTNET_CLI_HOME = Join-Path $repoRoot ".tools"
$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"

& $dotnet restore (Join-Path $repoRoot "src\Foton.Api\Foton.Api.csproj") -v:minimal
if ($LASTEXITCODE -ne 0) {
    throw "dotnet restore falhou com codigo $LASTEXITCODE."
}

& $dotnet build (Join-Path $repoRoot "src\Foton.Api\Foton.Api.csproj") --no-restore -v:minimal
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build falhou com codigo $LASTEXITCODE."
}
