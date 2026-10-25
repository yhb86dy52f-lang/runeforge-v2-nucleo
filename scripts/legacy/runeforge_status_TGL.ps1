$health = try { Invoke-RestMethod http://localhost:3001/health -TimeoutSec 2 } catch { $null }
$fastify = if($health.ok) { "ONLINE ($($health.version))" } else { "OFFLINE" }
Write-Host "--- RUNEFORGE V2.6.2-TGL ---"
Write-Host "[Fastify Backend]: $fastify"
Write-Host "[Clippings]: $($health.clippings) archivos"
Write-Host "[TGL Flota]: 721 unidades"
Write-Host "[KW]: Lerdo 25.5449,-103.5318 - 2 sensores Escort"
Write-Host "[CT]: Qro Mex-57D - En ruta 149km/h"
