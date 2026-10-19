# Runeforge Launcher v2.2 - Auto-reparable
function Test-OllamaAuto { try { $t=New-Object System.Net.Sockets.TcpClient; $a=$t.BeginConnect("127.0.0.1",11434,$null,$null); $w=$a.AsyncWaitHandle.WaitOne(1000,$false); if(-not $w){$t.Close();return $false}; $t.EndConnect($a); $t.Close(); return $true } catch { return $false } }
if (-not (Test-OllamaAuto)) { Start-Process "ollama" "serve" -WindowStyle Hidden; Start-Sleep 4 }
pm2 start ecosystem.config.js --update-env
Start-Process http://localhost:3100
