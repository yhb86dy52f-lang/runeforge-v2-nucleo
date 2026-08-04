param(
  [Parameter(Mandatory=$true)]
  [string]$JobJson,

  [string]$OutDir=""
)

$ErrorActionPreference="Stop"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$Utf8=[System.Text.UTF8Encoding]::new($false)
$Fence=([string][char]96)+([string][char]96)+([string][char]96)

if(-not(Test-Path -LiteralPath $JobJson)){
  throw "No existe JobJson: $JobJson"
}

$Root="C:\RUNEFOGE_PRO\runeforge"
$VisualBase=Join-Path $Root "data\visual_layout_engine"
$CatalogDir=Join-Path $VisualBase "catalogs"
$TraceDir=Join-Path $VisualBase "traces"

if([string]::IsNullOrWhiteSpace($OutDir)){
  $OutDir=Join-Path $VisualBase "outputs\compiled_prompts"
}

New-Item -ItemType Directory -Force -Path $OutDir,$TraceDir | Out-Null

$Job=Get-Content -LiteralPath $JobJson -Raw | ConvertFrom-Json
$TemplateManifest=Get-ChildItem -LiteralPath $CatalogDir -Filter "rf_visual_template_factory_manifest_*.json" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if(-not $TemplateManifest){
  throw "No encontré manifest de Template Factory en $CatalogDir"
}

$Templates=@(Get-Content -LiteralPath $TemplateManifest.FullName -Raw | ConvertFrom-Json)
$Template=$Templates | Where-Object {$_.tipo_visual -eq $Job.tipo_visual} | Select-Object -First 1

if(-not $Template){
  $TiposDisponibles=($Templates | Select-Object -ExpandProperty tipo_visual) -join ", "
  throw "No existe template para tipo_visual='$($Job.tipo_visual)'. Disponibles: $TiposDisponibles"
}

$PromptTemplate=Get-Content -LiteralPath $Template.prompt_template -Raw
$Checklist=Get-Content -LiteralPath $Template.checklist -Raw
$NegativeRules=Get-Content -LiteralPath $Template.negative_rules -Raw
$LayoutSpecTemplate=Get-Content -LiteralPath $Template.layout_spec_template -Raw | ConvertFrom-Json

$Faltantes=@()
foreach($Campo in @("tipo_visual","objetivo_usuario","prompt_original","metadata_extraida","layout_spec","referencias")){
  if($Job.PSObject.Properties.Name -notcontains $Campo){
    $Faltantes+=$Campo
  }else{
    $Valor=$Job.$Campo
    if($null -eq $Valor){$Faltantes+=$Campo}
    elseif($Valor -is [string] -and ([string]::IsNullOrWhiteSpace($Valor) -or $Valor -match "^PENDIENTE")){$Faltantes+=$Campo}
  }
}

$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$JobId=if($Job.job_id){[string]$Job.job_id}else{"rf_visual_job"}
$JobSafe=($JobId -replace '[\\/:*?"<>| ]','_')
$OutMd=Join-Path $OutDir ("compiled_prompt_"+$JobSafe+"_"+$Stamp+".md")
$OutJson=Join-Path $OutDir ("compiled_prompt_"+$JobSafe+"_"+$Stamp+".json")
$TraceJson=Join-Path $TraceDir ("rf_visual_prompt_compiler_v1_"+$JobSafe+"_"+$Stamp+".json")

$MetadataJson=($Job.metadata_extraida | ConvertTo-Json -Depth 12)
$LayoutJson=($Job.layout_spec | ConvertTo-Json -Depth 12)
$RefsJson=($Job.referencias | ConvertTo-Json -Depth 12)

$Lines=@()
$Lines+="# RF_VISUAL_PROMPT_COMPILER_V1"
$Lines+=""
$Lines+="## TIPO VISUAL"
$Lines+=$Job.tipo_visual
$Lines+=""
$Lines+="## OBJETIVO DEL USUARIO"
$Lines+=$Job.objetivo_usuario
$Lines+=""
$Lines+="## PROMPT ORIGINAL"
$Lines+=$Job.prompt_original
$Lines+=""
$Lines+="## METADATA EXTRAIDA"
$Lines+=($Fence+"json")
$Lines+=$MetadataJson
$Lines+=$Fence
$Lines+=""
$Lines+="## LAYOUT_SPEC"
$Lines+=($Fence+"json")
$Lines+=$LayoutJson
$Lines+=$Fence
$Lines+=""
$Lines+="## REFERENCIAS / EVIDENCIA"
$Lines+=($Fence+"json")
$Lines+=$RefsJson
$Lines+=$Fence
$Lines+=""
$Lines+="## TEMPLATE BASE"
$Lines+=$PromptTemplate
$Lines+=""
$Lines+="## CHECKLIST"
$Lines+=$Checklist
$Lines+=""
$Lines+="## NEGATIVE RULES"
$Lines+=$NegativeRules
$Lines+=""
$Lines+="## INSTRUCCION FINAL COMPILADA"
$Lines+="Genera una imagen técnica controlada basada estrictamente en el layout_spec, metadata y referencias indicadas. No inventes elementos no declarados. Si falta información, marca PENDIENTE en vez de completar al azar. Mantén estilo técnico limpio, labels legibles, coherencia geométrica y trazabilidad visual."
$Lines+=""
$Lines+="## VALIDACION PREVIA"
if($Faltantes.Count -eq 0){
  $Lines+="- OK: job completo para compilación."
}else{
  foreach($F in $Faltantes){$Lines+=("- PENDIENTE: " + $F)}
}

[System.IO.File]::WriteAllText($OutMd,($Lines -join [Environment]::NewLine),$Utf8)

$State=[ordered]@{
  timestamp=(Get-Date).ToString("o")
  estado="RF_VISUAL_PROMPT_COMPILER_V1_1_COMPILED"
  job_json=$JobJson
  tipo_visual=$Job.tipo_visual
  template_manifest=$TemplateManifest.FullName
  template_dir=$Template.template_dir
  output_md=$OutMd
  output_json=$OutJson
  trace=$TraceJson
  faltantes=$Faltantes
  ready_for_image_generation=($Faltantes.Count -eq 0)
  backend="NO_TOCADO"
  siguiente="RF_VISUAL_GENERATION_GATE_V1"
}

[System.IO.File]::WriteAllText($OutJson,($State | ConvertTo-Json -Depth 12),$Utf8)
[System.IO.File]::WriteAllText($TraceJson,($State | ConvertTo-Json -Depth 12),$Utf8)

[pscustomobject]$State