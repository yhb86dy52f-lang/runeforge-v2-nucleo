$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
Set-Location $root
Write-Host "ROOT: $root" -ForegroundColor Cyan
$files = @(
    "AGENTS.md",
    ".env.template",
    "config\llm-profiles.json",
    "src\backend\services\llm\BaseProvider.js",
    "src\backend\services\llm\adapters\ollama.js",
    "src\backend\services\llm\factory.js",
    "config\obsidian\obsidian-web-clipper-settings.json"
)
foreach ($f in $files) {
    if (Test-Path $f) {
        Write-Host "  exists $f" -ForegroundColor Green
    } else {
        Write-Host "  missing $f" -ForegroundColor Red
        exit 1
    }
}
Write-Host "`n=== Validando ===" -ForegroundColor Cyan
$json = Get-Content "config\llm-profiles.json" | ConvertFrom-Json
Write-Host "JSON OK: defaultProvider=$($json.defaultProvider)" -ForegroundColor Green
node -e "const f=require('./src/backend/services/llm/factory.js'); f.createProvider('ollama').status().then(console.log).catch(console.error)" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "factory cargado" -ForegroundColor Green
} else {
    Write-Host "factory falló" -ForegroundColor Red
    exit 1
}
Write-Host "`nBootstrap Etapa 1 completado. Siguiente: .\runeforge_launcher.ps1" -ForegroundColor Green
