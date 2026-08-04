param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [Parameter(Mandatory=$true)]
    [string]$Body,

    [ValidateSet("INBOX","RUNEFORGE","BITACORA","COMANDO","LOG","EVIDENCIA")]
    [string]$Category = "INBOX",

    [string]$Source = "manual",

    [string[]]$Tags = @("runeforge","obsidian")
)

Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)

$Root="C:\RUNEFOGE_PRO\runeforge"
$Vault="C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_OBSIDIAN"
$TraceDir=Join-Path $Root "data\obsidian_bridge"

if(-not(Test-Path -LiteralPath $Root)){throw "No existe Root: $Root"}

New-Item -ItemType Directory -Force -Path $Vault,$TraceDir | Out-Null

$folderMap=@{
    INBOX="00_INBOX"
    RUNEFORGE="01_RUNEFORGE"
    BITACORA="02_BITACORAS"
    COMANDO="03_COMANDOS"
    LOG="04_LOGS"
    EVIDENCIA="05_EVIDENCIAS"
}

function ConvertTo-SafeFileName {
    param([string]$Text)

    $safe=$Text -replace '[\\/:*?"<>|]', '-'
    $safe=$safe -replace '\s+', '_'
    $safe=$safe.Trim(" ",".","_","-")

    if([string]::IsNullOrWhiteSpace($safe)){
        $safe="nota_runeforge"
    }

    if($safe.Length -gt 80){
        $safe=$safe.Substring(0,80)
    }

    return $safe
}

function ConvertTo-YamlSingleQuoted {
    param([string]$Text)

    $clean=$Text -replace "'", "''"
    return "'" + $clean + "'"
}

$stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$iso=(Get-Date).ToString("o")
$id="rf_obsidian_"+$stamp
$folderName=$folderMap[$Category]
$TargetDir=Join-Path $Vault $folderName

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$safeTitle=ConvertTo-SafeFileName -Text $Title
$NotePath=Join-Path $TargetDir ($stamp+"_"+$safeTitle+".md")
$TracePath=Join-Path $TraceDir ($id+".json")
$CurrentPath=Join-Path $TraceDir "obsidian_bridge_current.json"

$lines=New-Object System.Collections.Generic.List[string]

$lines.Add("---") | Out-Null
$lines.Add("rf_id: "+$id) | Out-Null
$lines.Add("title: "+(ConvertTo-YamlSingleQuoted -Text $Title)) | Out-Null
$lines.Add("created: "+$iso) | Out-Null
$lines.Add("category: "+$Category) | Out-Null
$lines.Add("source: "+(ConvertTo-YamlSingleQuoted -Text $Source)) | Out-Null
$lines.Add("status: active") | Out-Null
$lines.Add("tags:") | Out-Null

foreach($tag in $Tags){
    $cleanTag=($tag -replace '\s+','_')
    $cleanTag=$cleanTag -replace '[^A-Za-z0-9_\-]',''
    if(-not [string]::IsNullOrWhiteSpace($cleanTag)){
        $lines.Add("  - "+$cleanTag) | Out-Null
    }
}

$lines.Add("---") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("# "+$Title) | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Metadata") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("```txt") | Out-Null
$lines.Add("rf_id="+$id) | Out-Null
$lines.Add("category="+$Category) | Out-Null
$lines.Add("source="+$Source) | Out-Null
$lines.Add("created="+$iso) | Out-Null
$lines.Add("```") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Contenido") | Out-Null
$lines.Add("") | Out-Null
$lines.Add($Body) | Out-Null
$lines.Add("") | Out-Null
$lines.Add("## Trazabilidad") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("```txt") | Out-Null
$lines.Add("root="+$Root) | Out-Null
$lines.Add("vault="+$Vault) | Out-Null
$lines.Add("note="+$NotePath) | Out-Null
$lines.Add("trace="+$TracePath) | Out-Null
$lines.Add("backend=NO_TOCADO") | Out-Null
$lines.Add("```") | Out-Null

$content=$lines -join [Environment]::NewLine

Set-Content -LiteralPath $NotePath -Value $content -Encoding utf8BOM -Force

$trace=[pscustomobject]@{
    ts=$iso
    status="OBSIDIAN_NOTE_CREATED"
    id=$id
    title=$Title
    category=$Category
    source=$Source
    note_path=$NotePath
    trace_path=$TracePath
    vault=$Vault
    root=$Root
    backend="NO_TOCADO"
    runeforge="OBSIDIAN_BRIDGE_V1"
}

$trace | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $TracePath -Encoding utf8BOM -Force
$trace | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CurrentPath -Encoding utf8BOM -Force

Write-Host "`n[NOTE_CREATED]"
Get-Item -LiteralPath $NotePath | Select-Object FullName,Length,LastWriteTime | Format-List

Write-Host "`n[TRACE]"
Get-Content -LiteralPath $TracePath -Raw

Write-Host "`n[SUMMARY]"
[pscustomobject]@{
    Estado="OBSIDIAN_NOTE_CREATED"
    Id=$id
    Category=$Category
    Note=$NotePath
    Trace=$TracePath
    Backend="NO_TOCADO"
    Runeforge="OBSIDIAN_BRIDGE_V1"
    Siguiente="Validar nota en Obsidian y luego crear comando remoto iPhone"
} | Format-List
