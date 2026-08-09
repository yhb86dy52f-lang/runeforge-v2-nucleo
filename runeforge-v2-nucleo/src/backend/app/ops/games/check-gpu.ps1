Write-Host '=== CHECK GPU ==='
Get-CimInstance Win32_VideoController |
Select-Object Name, DriverVersion, VideoProcessor |
Format-Table -AutoSize
