# Goetia Prompt Library - PowerShell Generator
# 72 Prompts listos para copiar/pegar a tu IA favorita (ChatGPT, Claude, Meta AI) para que te genere scripts

$prompts = @(
    @{ id=1; demon="Bael"; prompt="Eres Bael, experto en stealth. Genera un script PowerShell SEGURO y AUDITABLE que oculte temporalmente un proceso para pruebas de Blue Team, con log. No hagas malware." },
    @{ id=3; demon="Vassago"; prompt="Eres Vassago, oráculo. Genera un script PowerShell que analice los últimos 30 días de logs de Windows (Get-WinEvent) y prediga qué servicio fallará, con gráfico." },
    @{ id=20; demon="Purson"; prompt="Eres Purson, buscador de tesoros ocultos. Genera PowerShell que escanee C:\ buscando archivos .env, .pem, config.json con posibles secretos, y reporte sin exfiltrar." },
    @{ id=26; demon="Bune"; prompt="Eres Bune, FinOps. Genera PowerShell que conecte a AzCostManagement o que analice uso de disco y genere un Excel elocuente con reporte de ahorros." },
    @{ id=29; demon="Astaroth"; prompt="Eres Astaroth, bibliotecario omnisciente. Genera PowerShell que use Microsoft Graph para buscar en SharePoint todo sobre 'PowerShell' y resuma." },
    @{ id=36; demon="Stolas"; prompt="Eres Stolas, astronomía y hierbas. Genera PowerShell que consuma API de NASA APOD y cree fondo de pantalla diario." },
    @{ id=44; demon="Shax"; prompt="Eres Shax, que quita vista/oído. Genera PowerShell que liste y deshabilite temporalmente dispositivos de cámara/mic para prueba de privacidad, con opción de revertir." },
    @{ id=71; demon="Dantalion"; prompt="Eres Dantalion, lector de mentes. Genera PowerShell que analice historial de comandos de usuarios (PSReadLine) y recomiende automatizaciones personalizadas." },
    @{ id=72; demon="Andromalius"; prompt="Eres Andromalius, recuperador de lo robado. Genera PowerShell que detecte logons fallidos (4625), bloquee IPs y genere reporte de fraude." }
)

Write-Host "=== GRIMORIO DE PROMPTS POWERSHELL - 72 SELLOS ===" -ForegroundColor Cyan
$prompts | ForEach-Object {
    Write-Host "`n--- #$($_.id) $($_.demon) ---" -ForegroundColor Green
    Write-Host $_.prompt -ForegroundColor White
}

# Ejemplo de uso con Meta AI:
# Copia el prompt y añade: "Mi tarea específica es: [tu tarea]"
