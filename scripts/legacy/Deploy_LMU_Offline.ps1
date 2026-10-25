if ($PSCommandPath -ne $TargetScriptPath) {
    if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
    
    if ($PSCommandPath) {
        Copy-Item -Path $PSCommandPath -Destination $TargetScriptPath -Force
    } else {
        $ScriptContent = $MyInvocation.MyCommand.Definition
        Set-Content -Path $TargetScriptPath -Value $ScriptContent -Force
    }
    
    # Auto-ejecuta la versión guardada y termina la ejecución actual
    & pwsh -File $TargetScriptPath
    exit
}
