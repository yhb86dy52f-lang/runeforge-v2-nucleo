# RUNEFORGE SECRET TRIAGE REDACTED
# No imprime valores, solo archivos candidatos.

$Roots = @(
    "C:\RUNEFOGE_PRO\runeforge",
    "C:\Users\nesth\Documents\EL_ABISMO"
)

$Patterns = @(
    "password\s*[:=]",
    "passwd\s*[:=]",
    "secret\s*[:=]",
    "token\s*[:=]",
    "api[_-]?key\s*[:=]",
    "OPENAI_API_KEY",
    "GEMINI_API_KEY",
    "ANTHROPIC_API_KEY",
    "DATABASE_URL",
    "JWT_SECRET",
    "PRIVATE_KEY"
)

$Include = ".env",".txt",".md",".json",".yaml",".yml",".ps1",".js",".ts",".ahk"
$Exclude = "\\(node_modules|\.git|dist|build|backups|archive|hardening|audits)($|\\)"

$Found = foreach ($Root in $Roots) {
    if (-not (Test-Path $Root)) { continue }

    Get-ChildItem $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $Include -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch $Exclude -and
        $_.Length -lt 5MB
    } |
    ForEach-Object {
        $file = $_
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        foreach ($pattern in $Patterns) {
            if ($content -match $pattern) {
                [pscustomobject]@{
                    severity = "REVISAR"
                    file = $file.FullName
                    pattern = $pattern
                    value = "REDACTED"
                }
            }
        }
    }
}

$Found | Sort-Object file,pattern | Format-Table -AutoSize
Write-Host "`n[OK] Triage de secretos generado sin imprimir valores." -ForegroundColor Green
