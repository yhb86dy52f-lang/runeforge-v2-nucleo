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
if(-not(Test-Path -LiteralPath $Vault)){New-Item -ItemType Directory -Force -Path $Vault | Out-Null}
if(-not(Test-Path -LiteralPath $TraceDir)){New-Item -ItemType Directory -Force -Path $TraceDir | Out-Null}

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

$tagLines=@()
foreach($tag in $Tags){
    $cleanTag=($tag -replace '\s+','_')
    $tagLines += "  - $cleanTag"
}

$frontMatter=@(
    "---",
    "rf_id: $id",
    "title: `"$Title`"",
    "created: $iso",
    "category: $Category",
    "source: $Source",
    "status: active",
    "tags:"
) + $tagLines + @(
    "---",
    ""
)

$content=@(
    $frontMatter,
    "# $Title",
    "",
    "## Metadata",
    "",
    "```txt",
    "rf_id=$id",
    "category=$Category",
    "source=$Source",
    "created=$iso",
    "```",
    "",
    "## Contenido",
    "",
    $Body,
    "",
    "## Trazabilidad",
    "",
    "```txt",
    "root=$Root",
    "vault=$Vault",
    "note=$NotePath",
    "trace=$TracePath",
    "backend=NO_TOCADO",
    "```"
) -join "`r`n"

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
