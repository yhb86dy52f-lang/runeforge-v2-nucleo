$ExportSource = "C:\Users\nesth\Documents\EL_ABISMO\PWSH RESULTADOS CODIGOS"
if (-not (Test-Path -LiteralPath $ExportSource)) {
    New-Item -ItemType Directory -Path $ExportSource -Force | Out-Null
}
Start-Process $ExportSource
