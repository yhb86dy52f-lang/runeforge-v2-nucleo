[RUNEFORGE_MEMORY_CLAUSE_2026-04-24_V43.6.1_AHK_CALLBACK_FIX]

Fecha: 2026-04-24
Estado: V43.6.1 AHK Callback Fix aplicado

Se corrigió el panel maestro V43.5 para que los botones:
- 🧊 Mini
- 🔄 Reiniciar

usen callbacks seguros:
- (*) => LaunchMini()
- (*) => RestartPanel()

También se aseguraron las funciones:
- LaunchMini(*)
- RestartPanel(*)

Se repararon/completaron comandos de shell:
- rf-panel
- rf-panel-full
- rf-mini

Backend no fue tocado.
