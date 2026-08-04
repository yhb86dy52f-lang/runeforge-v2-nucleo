# RF_ROOT_CLEANUP_MOVE_PLAN_CURRENT

Fecha actualización: 2026-06-07 14:34:12

## Resultado
- Estado: MOVE_PLAN_DONE_NO_MOVE
- Base: C:\RUNEFOGE_PRO
- Total items: 28
- Aplicables a movimiento futuro: 21
- Bloqueados: 3
- Conservados en sitio: 4
- Acción real: NO_MOVE_NO_DELETE

## Resumen por decisión
- MOVER_A_MISC_UNSORTED: 9
- MOVER_A_ARCHIVE_LEGACY: 7
- CONSERVAR_EN_SITIO: 4
- MOVER_A_KNOWLEDGE_REVIEW: 3
- BLOQUEADO_NO_TOCAR: 1
- BLOQUEADO_REVISION_MANUAL: 1
- BLOQUEADO_VALIDAR_GIT: 1
- MOVER_A_ARCHIVE_BACKUPS: 1
- MOVER_A_LAB_VIDEO: 1

## Plan detallado
- video_clean_perrito | MOVER_A_LAB_VIDEO | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\lab\video\video_clean_perrito
- USB_BACKUPS | MOVER_A_ARCHIVE_BACKUPS | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\old_backups\USB_BACKUPS
- tools | CONSERVAR_EN_SITIO | aplicable=False | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\tools
- runeforge-v2-ready | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\runeforge-v2-ready
- runeforge-mvp | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\runeforge-mvp
- runeforge-datahub | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\runeforge-datahub
- RUNEFORGE_KNOWLEDGE | CONSERVAR_EN_SITIO | aplicable=False | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\RUNEFORGE_KNOWLEDGE
- runeforge | BLOQUEADO_NO_TOCAR | aplicable=False | riesgo=ALTO | destino=C:\RUNEFOGE_PRO\runeforge
- memoria-ia-pack | MOVER_A_KNOWLEDGE_REVIEW | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\RUNEFORGE_KNOWLEDGE\memoria-ia-pack
- memoria-ia | MOVER_A_KNOWLEDGE_REVIEW | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\RUNEFORGE_KNOWLEDGE\memoria-ia
- lab_v1_1_files | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\lab_v1_1_files
- lab | CONSERVAR_EN_SITIO | aplicable=False | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\lab
- essential_only | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\essential_only
- diagnostico | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\diagnostico
- core | MOVER_A_ARCHIVE_LEGACY | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\_archive\legacy_projects\core
- backups | CONSERVAR_EN_SITIO | aplicable=False | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\backups
- .tmp.driveupload | BLOQUEADO_REVISION_MANUAL | aplicable=False | riesgo=MEDIO | destino=PENDIENTE
- .git | BLOQUEADO_VALIDAR_GIT | aplicable=False | riesgo=ALTO | destino=C:\RUNEFOGE_PRO\_archive\git_root_legacy\.git
- Runeforge V2 Scaffold Base.pdf | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\Runeforge V2 Scaffold Base.pdf
- Runeforge V2 Scaffold Base (1).pdf | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\Runeforge V2 Scaffold Base (1).pdf
- Runeforge V2 — Bitácora Operativa.pdf | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\Runeforge V2 — Bitácora Operativa.pdf
- Runeforge V2 — Bitácora Operativa (1).pdf | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\Runeforge V2 — Bitácora Operativa (1).pdf
- Prompt Codex Runeforge Final.pdf | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\Prompt Codex Runeforge Final.pdf
- netfix_pre_20260505_214746.txt | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\netfix_pre_20260505_214746.txt
- MEMORIA RUNEGORGE.txt | MOVER_A_KNOWLEDGE_REVIEW | aplicable=True | riesgo=MEDIO | destino=C:\RUNEFOGE_PRO\RUNEFORGE_KNOWLEDGE\MEMORIA RUNEGORGE.txt
- inventario_20260524_032705.csv | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\inventario_20260524_032705.csv
- gpu_info.txt | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\gpu_info.txt
- dxdiag.txt | MOVER_A_MISC_UNSORTED | aplicable=True | riesgo=BAJO | destino=C:\RUNEFOGE_PRO\_archive\misc_unsorted\dxdiag.txt

## Impacto
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

## Siguiente
- RF_ROOT_CLEANUP_APPLY_DRYRUN_CURRENT_V1
