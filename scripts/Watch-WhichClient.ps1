# ============================================================
#  Watch-WhichClient.ps1
#  THE LIE DETECTOR: run this, THEN launch from ThwargLauncher.
#  The moment acclient.exe starts, this prints EXACTLY which
#  client folder is really running - STOCK or CUSTOM - and
#  keeps watching until the client exits.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Watch-WhichClient.ps1"
# ============================================================
$ErrorActionPreference = "SilentlyContinue"

Write-Host "CLIENT LAUNCH WATCHER" -ForegroundColor Magenta
Write-Host "Waiting for acclient.exe to start... (now go launch from ThwargLauncher)" -ForegroundColor Cyan
Write-Host "(Ctrl+C here exits the watcher anytime - it never touches the game)`n"

# Wait for launch
$proc = $null
while (-not $proc) {
    Start-Sleep -Milliseconds 500
    $proc = Get-Process acclient -ErrorAction SilentlyContinue | Select-Object -First 1
}

$path = $proc.Path
$started = Get-Date
Write-Host "ACCLIENT STARTED (PID $($proc.Id)) at $($started.ToString('HH:mm:ss'))" -ForegroundColor Green
Write-Host "  Full path: $path"

if ($path -like "*AC-Stock*") {
    Write-Host "`n  >>> RUNNING: AC-STOCK (the stock-portal test client) <<<" -ForegroundColor Green
} elseif ($path -like "*Asheron's Call*") {
    Write-Host "`n  >>> RUNNING: CUSTOM CLIENT (your 2084 set) - NOT the test client! <<<" -ForegroundColor Red
    Write-Host "  Thwarg ignored the AC-Stock path. Fix the client-path field and relaunch." -ForegroundColor Red
} else {
    Write-Host "`n  >>> RUNNING FROM UNEXPECTED LOCATION - see path above <<<" -ForegroundColor Yellow
}

# Watch until it exits, report lifetime
Write-Host "`nWatching the session (this window updates when the client closes)..." -ForegroundColor Cyan
while (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue) { Start-Sleep -Seconds 2 }
$lifetime = [math]::Round(((Get-Date) - $started).TotalSeconds)

Write-Host "`nCLIENT EXITED after $lifetime seconds." -ForegroundColor Magenta
if ($lifetime -gt 150) {
    Write-Host "  That's past the death-zone (~100s) - if you logged out yourself, that's a SURVIVAL." -ForegroundColor Green
} else {
    Write-Host "  Under ~2 minutes - consistent with the timeout/boot pattern." -ForegroundColor Yellow
}
Write-Host "`nReport back: STOCK or CUSTOM, and the lifetime seconds."
