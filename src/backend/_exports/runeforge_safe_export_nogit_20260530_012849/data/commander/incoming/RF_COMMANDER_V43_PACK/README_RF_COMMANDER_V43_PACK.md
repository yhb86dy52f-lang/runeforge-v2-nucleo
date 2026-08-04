# RF COMMANDER V43 PACK

## Veredicto

- CANONICO FULL: `RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk`
- CANONICO QUICK: `RUNEFORGE_COMMANDER_V43_6_QUICK_DOCK.ahk`
- LEGADO/REFERENCIA: V43.4, V42, V41

## Flujo recomendado

```txt
Start-Runeforge-Panel.ps1 -Mode Full   -> abre V43.5
Start-Runeforge-Panel.ps1 -Mode Quick  -> abre V43.6
Start-Runeforge-Panel.ps1 -Mode Both   -> abre ambos
```

## Riesgos

- Los scripts AHK se autoelevan como admin.
- V41/V42 tienen funciones de inyección/ghost/export bridge; conservar como referencia o módulo legado.
- V43.5 y V43.6 siguen pudiendo pegar/enviar teclas a la ventana activa. Mantener SafeMode ON cuando aplique.

## Validación inicial

Ejecutar primero:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\RF_COMMANDER_AUDIT_V43_PACK.ps1
```

Después, si el reporte sale OK:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\RF_COMMANDER_INSTALL_V43_PACK.ps1
```
