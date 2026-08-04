# RF_ROOT_CLEANUP_POSTCHECK_CURRENT

Fecha actualización: 2026-06-09 03:14:12

## Resultado
- Estado: ROOT_CLEANUP_POSTCHECK_OK
- Base: C:\RUNEFOGE_PRO
- Apply status: APPLY_MOVE_OK
- Items revisados: 21
- Postcheck OK: 21
- Postcheck revisión: 0
- Protegidos OK: 3
- Protegidos revisión: 0
- Acción real: POSTCHECK_ONLY_NO_MOVE_NO_DELETE
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

## Validación de movidos
- video_clean_perrito | POSTCHECK_OK | origen_existe=False | destino_existe=True
- USB_BACKUPS | POSTCHECK_OK | origen_existe=False | destino_existe=True
- runeforge-v2-ready | POSTCHECK_OK | origen_existe=False | destino_existe=True
- runeforge-mvp | POSTCHECK_OK | origen_existe=False | destino_existe=True
- runeforge-datahub | POSTCHECK_OK | origen_existe=False | destino_existe=True
- memoria-ia-pack | POSTCHECK_OK | origen_existe=False | destino_existe=True
- memoria-ia | POSTCHECK_OK | origen_existe=False | destino_existe=True
- lab_v1_1_files | POSTCHECK_OK | origen_existe=False | destino_existe=True
- essential_only | POSTCHECK_OK | origen_existe=False | destino_existe=True
- diagnostico | POSTCHECK_OK | origen_existe=False | destino_existe=True
- core | POSTCHECK_OK | origen_existe=False | destino_existe=True
- Runeforge V2 Scaffold Base.pdf | POSTCHECK_OK | origen_existe=False | destino_existe=True
- Runeforge V2 Scaffold Base (1).pdf | POSTCHECK_OK | origen_existe=False | destino_existe=True
- Runeforge V2 — Bitácora Operativa.pdf | POSTCHECK_OK | origen_existe=False | destino_existe=True
- Runeforge V2 — Bitácora Operativa (1).pdf | POSTCHECK_OK | origen_existe=False | destino_existe=True
- Prompt Codex Runeforge Final.pdf | POSTCHECK_OK | origen_existe=False | destino_existe=True
- netfix_pre_20260505_214746.txt | POSTCHECK_OK | origen_existe=False | destino_existe=True
- MEMORIA RUNEGORGE.txt | POSTCHECK_OK | origen_existe=False | destino_existe=True
- inventario_20260524_032705.csv | POSTCHECK_OK | origen_existe=False | destino_existe=True
- gpu_info.txt | POSTCHECK_OK | origen_existe=False | destino_existe=True
- dxdiag.txt | POSTCHECK_OK | origen_existe=False | destino_existe=True

## Protegidos
- runeforge | existe=True | C:\RUNEFOGE_PRO\runeforge
- .git | existe=True | C:\RUNEFOGE_PRO\.git
- .tmp.driveupload | existe=True | C:\RUNEFOGE_PRO\.tmp.driveupload

## Raíz actual
- DIR | _archive
- FILE | .env
- FILE | .env.example
- DIR | .git
- FILE | .gitignore
- DIR | .tmp.drivedownload
- DIR | .tmp.driveupload
- DIR | 01_INBOX_WEB
- DIR | backups
- FILE | forge_ui_nexo_v_0.jsx
- DIR | lab
- DIR | logs
- DIR | node_modules
- FILE | package-lock.json
- FILE | package.json
- FILE | README.md
- DIR | rf_temp
- FILE | RUNEFOGE_PRO.zip
- DIR | runeforge
- DIR | RUNEFORGE_KNOWLEDGE
- FILE | RUNEFORGE_MASTER_FUSIONADO_2026-03-20.zip
- FILE | RUNEFORGE_MASTER_FUSIONADO.md
- FILE | RUNEFORGE_MASTER_FUSIONADO1.zip
- FILE | runeforge_status_check.txt
- DIR | runeforge-mobile-relay
- FILE | runeforge-mvp.zip
- FILE | runeforge-relay.code-workspace
- DIR | scripts
- DIR | tools
- FILE | tsconfig.json
- FILE | yhb86dy52f-lang.github-devices-2026-03-21T11-40-38-359Z.csv

## Rollback
- Manifest: C:\RUNEFOGE_PRO\runeforge\data\maintenance\root_cleanup\rf_root_cleanup_rollback_manifest_current.json
- Script: C:\RUNEFOGE_PRO\runeforge\data\maintenance\root_cleanup\Invoke-RFRootCleanupRollback-Current.ps1

## Siguiente
- RF_ROOT_CLEANUP_CLOSE_CURRENT_V1
