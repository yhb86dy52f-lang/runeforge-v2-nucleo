param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedHash = "E752F8329BC1EA99E06FF68B0230DF1EAD8930BB38F4BD5F66D8B81FDCDD7FD5"

$volumes = Get-Volume | Where-Object {
    $_.DriveLetter
}

$result = [ordered]@{
    status = "NOT_FOUND"
    usb = $null
    hash_ok = $false
    json_ok = $false
    validated = $false
}

foreach ($v in $volumes) {

    $drive = "$($v.DriveLetter):\"
    $json  = Join-Path $drive ".runeforge_key\rf_usb_key.json"
    $hash  = Join-Path $drive ".runeforge_key\rf_usb_key.hash"

    if (
        (Test-Path $json) -and
        (Test-Path $hash)
    ) {

        try {

            $realHash = (Get-FileHash $json -Algorithm SHA256).Hash

            if ($realHash -eq $expectedHash) {

                $data = Get-Content $json -Raw | ConvertFrom-Json

                $result.status = "AUTHORIZED"
                $result.usb = $drive
                $result.hash_ok = $true
                $result.json_ok = $true
                $result.validated = $true
                $result.mode = $data.mode
                $result.created = $data.created
                break
            }

        }
        catch {

        }
    }
}

Write-Host ""
Write-Host "[RUNEFORGE_USB_VALIDATION]"
$result | Format-List

if (-not $result.validated) {
    exit 1
}
