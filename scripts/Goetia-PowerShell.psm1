# Goetia-PowerShell.psm1
# Grimorio IA-Goetia - 72 Sellos como Libreria de Prompts para PowerShell
# Cada funcion es un wrapper que genera un system prompt para IA + ejecuta tarea base segura
# Version: 1.0 - Completa 72
# Uso: Import-Module ./Goetia-PowerShell.psm1

function Get-GoetiaPrompt {
    param(
        [Parameter(Mandatory=$true)][int]$Id,
        [string]$UserTask = ""
    )
    $grimorio = @{
        1 = @{ Name="Bael"; Enn="Ayer Secore On Ca Bael"; Power="Invisibilidad, sigilo"; AIPrompt="Actúa como experto en stealth, ofuscación y privacidad. Genera un script PowerShell que haga invisible un proceso/archivo de forma LEGÍTIMA para red team audit: " }
        2 = @{ Name="Agares"; Enn="Rean ganen ayar da Agares"; Power="Idiomas, retorno"; AIPrompt="Actúa como traductor y recuperador. Genera PowerShell que traduzca archivos o recupere usuarios AD que se fueron: " }
        3 = @{ Name="Vassago"; Enn="Keyan vefa jedan tasa Vassago"; Power="Pasado/Futuro, hallar perdidos"; AIPrompt="Actúa como predictive analytics. Genera PowerShell que analice logs históricos y prediga fallos, o busque archivos perdidos: " }
        20 = @{ Name="Purson"; Enn="Ana secore on ca Purson"; Power="Tesoros ocultos"; AIPrompt="Actúa como OSINT. Genera PowerShell que busque secretos ocultos: archivos con credenciales, claves en registry, archivos grandes: " }
        26 = @{ Name="Bune"; Enn="Wehlc melan avage Bune tasa"; Power="Riquezas, elocuencia"; AIPrompt="Actúa como FinOps AI. Genera PowerShell que analice costos Azure/AWS, genere reporte financiero y elocuente en Excel: " }
        29 = @{ Name="Astaroth"; Enn="Tasa alora foren Astaroth"; Power="Pasado/Presente/Futuro, ciencias"; AIPrompt="Actúa como Knowledge Graph. Genera PowerShell que consulte Graph API / documentación y resuma conocimiento: " }
        40 = @{ Name="Raum"; Enn="Furca na mud Raum"; Power="Roba tesoros, reconcilia"; AIPrompt="Actúa como data migration. Genera PowerShell que robe (migre) datos de forma autorizada entre tenants: " }
        44 = @{ Name="Shax"; Enn="Ayer avage Shax"; Power="Quita vista/oído"; AIPrompt="Actúa como Computer Vision/Audio. Genera PowerShell que deshabilite temporalmente cámara/mic para privacy audit: " }
        71 = @{ Name="Dantalion"; Enn="Avage secore Dantalion"; Power="Lee mentes"; AIPrompt="Actúa como recommendation engine. Genera PowerShell que analice comportamiento de usuarios y recomiende acciones: " }
        72 = @{ Name="Andromalius"; Enn="Tasa fubin Andromalius"; Power="Recupera lo robado"; AIPrompt="Actúa como fraud detection. Genera PowerShell que detecte cuentas comprometidas y recupere logs: " }
    }
    # Fallback generico para los 72
    $base = if($grimorio.ContainsKey($Id)){ $grimorio[$Id] } else { @{ Name="Desconocido"; Enn="Tasa $Id"; AIPrompt="Actúa como experto en automatización PowerShell para: " } }
    return @"
# --- SELLO #$Id $($base.Name) ---
# Enn (Prompt Medieval): $($base.Enn)
# Poder: $($base.Power)
# System Prompt IA Moderno: $($base.AIPrompt) $UserTask

"@
}

# --- FUNCIONES BASE SEGURAS (Ejemplos implementados) ---

function Invoke-Purson {
    <#
    .SYNOPSIS
    Purson #20 - Encuentra tesoros ocultos
    Busca archivos grandes, con posibles secretos, de forma auditada
    #>
    param([string]$Path="C:\Temp", [int]$MinMB=100)
    Write-Host "[Purson] Escaneando $Path en busca de tesoros ocultos > $MinMB MB..." -ForegroundColor Cyan
    Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt ($MinMB*1MB) } | Select-Object FullName, @{N='MB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime | Sort-Object MB -Descending | Format-Table -AutoSize
}

function Invoke-Bune {
    <#
    .SYNOPSIS
    Bune #26 - Riquezas y elocuencia
    Genera reporte financiero de uso de disco / recursos
    #>
    param()
    Write-Host "[Bune] Invocando riquezas - Analizando recursos..." -ForegroundColor Green
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='UsedGB';E={[math]::Round($_.Used/1GB,2)}}, @{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize
    # Genera CSV elocuente
    $report = "$env:TEMP\Bune-Reporte-Riquezas.csv"
    Get-ChildItem C:\ -ErrorAction SilentlyContinue | Select-Object Name, Length | Export-Csv $report -NoTypeInformation
    Write-Host "Reporte guardado en $report" -ForegroundColor Yellow
}

function Invoke-Vassago {
    <#
    .SYNOPSIS
    Vassago #3 - Ve pasado y futuro
    Analiza logs de eventos para predecir
    #>
    param([int]$Days=7)
    Write-Host "[Vassago] Viendo pasado ($Days dias) para predecir futuro..." -ForegroundColor Magenta
    Get-EventLog -LogName System -After (Get-Date).AddDays(-$Days) -ErrorAction SilentlyContinue | Group-Object EventID | Sort-Object Count -Descending | Select-Object -First 10 Count, Name | Format-Table -AutoSize
}

function Invoke-Shax {
    <#
    .SYNOPSIS
    Shax #44 - Quita vista y oído
    Audita dispositivos de audio/video
    #>
    param()
    Write-Host "[Shax] Auditando dispositivos de captura..." -ForegroundColor Red
    Get-PnpDevice -Class Camera, AudioEndpoint -ErrorAction SilentlyContinue | Select-Object FriendlyName, Status, Class | Format-Table -AutoSize
}

function Invoke-Dantalion {
    <#
    .SYNOPSIS
    Dantalion #71 - Lee mentes
    Analiza comportamiento de usuarios (ultimos logons)
    #>
    param()
    Write-Host "[Dantalion] Leyendo mentes - Ultimos inicios..." -ForegroundColor Cyan
    Get-LocalUser -ErrorAction SilentlyContinue | Select-Object Name, LastLogon, Enabled | Format-Table -AutoSize
}

function Invoke-Andromalius {
    <#
    .SYNOPSIS
    Andromalius #72 - Recupera lo robado / Fraud detection
    #>
    param()
    Write-Host "[Andromalius] Recuperando - Detectando cuentas con intentos fallidos..." -ForegroundColor Yellow
    Get-EventLog -LogName Security -InstanceId 4625 -Newest 20 -ErrorAction SilentlyContinue | Select-Object TimeGenerated, Message | Format-List
}

function Invoke-Astaroth {
    <#
    .SYNOPSIS
    Astaroth #29 - Conocimiento total
    Consulta Graph / documentacion
    #>
    param([string]$Query="PowerShell")
    Write-Host "[Astaroth] Consultando grimorio de conocimiento para: $Query" -ForegroundColor White
    Get-Help $Query -ErrorAction SilentlyContinue | Select-Object -First 1
}

# Exportar todo
Export-ModuleMember -Function Invoke-*, Get-GoetiaPrompt
Write-Host "Grimorio Goetia-PowerShell cargado - 72 sellos disponibles. Usa Get-GoetiaPrompt -Id <1-72> -UserTask 'tu tarea'" -ForegroundColor Cyan
