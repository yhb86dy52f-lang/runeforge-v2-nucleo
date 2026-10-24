# ==============================================================================
# RUNEFORGE INIT (Lanzado por Windows Terminal)
# ==============================================================================
# Si el perfil no se ha cargado en esta sesión, lo carga.
if (-not $global:RUNEFORGE_LOADED) {
    if (Test-Path $PROFILE.CurrentUserAllHosts) {
        . $PROFILE.CurrentUserAllHosts
    }
}

# Mostrar reporte de estado (solo una vez al inicio)
if (Get-Command Show-RuneforgeStatus -ErrorAction SilentlyContinue) {
    Show-RuneforgeStatus
}