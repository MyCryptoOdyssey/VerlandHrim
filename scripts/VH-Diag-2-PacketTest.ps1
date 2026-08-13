# ============================================================
#  VH-Diag-2-PacketTest.ps1
#  THE DECISIVE TEST: do the server's world-entry packets
#  (port 9001) actually ARRIVE at this PC?
#  Uses Windows' built-in pktmon - no Wireshark install needed.
#
#  RUN AS ADMINISTRATOR:
#   1. Right-click PowerShell -> "Run as Administrator"
#   2. powershell -ExecutionPolicy Bypass -File .\VH-Diag-2-PacketTest.ps1
#   3. When told, do ONE login attempt to Verland_Hrim, let it
#      time out (or succeed!), then press Enter here.
# ============================================================

$ServerIP = "45.76.62.139"
$Dir = "C:\vh-diag"

# ---- Admin check ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "MUST RUN AS ADMINISTRATOR. Right-click PowerShell -> Run as Administrator, then rerun." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $Dir -Force | Out-Null
Write-Host "`n=== VH DIAG 2: RECEIVING-END PACKET TEST ===" -ForegroundColor Magenta

# ---- Clean slate ----
pktmon stop 2>$null | Out-Null
pktmon filter remove 2>$null | Out-Null
Remove-Item "$Dir\cap.etl","$Dir\cap.txt" -ErrorAction SilentlyContinue

# ---- Filters: game ports only ----
pktmon filter add AC9000 -p 9000 | Out-Null
pktmon filter add AC9001 -p 9001 | Out-Null
Write-Host "[1] Capture filters set for UDP 9000/9001."

# ---- Start capture ----
pktmon start --capture --pkt-size 0 -f "$Dir\cap.etl" | Out-Null
Write-Host "[2] CAPTURE RUNNING." -ForegroundColor Green
Write-Host ""
Write-Host ">>> NOW: go to ThwargLauncher and do ONE login attempt to Verland_Hrim ($ServerIP)." -ForegroundColor Yellow
Write-Host ">>> Let it fully time out (or walk around if it works!). Then come back here." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter AFTER the attempt has ended"

# ---- Stop & convert ----
pktmon stop | Out-Null
Write-Host "[3] Capture stopped. Converting (may take a moment)..."
pktmon etl2txt "$Dir\cap.etl" -o "$Dir\cap.txt" 2>$null | Out-Null
if (-not (Test-Path "$Dir\cap.txt")) { pktmon format "$Dir\cap.etl" -o "$Dir\cap.txt" 2>$null | Out-Null }
if (-not (Test-Path "$Dir\cap.txt")) {
    Write-Host "Conversion failed - raw capture kept at $Dir\cap.etl" -ForegroundColor Red
    exit 1
}

# ---- Analyze ----
Write-Host "[4] Analyzing..." -ForegroundColor Cyan
$lines = Get-Content "$Dir\cap.txt"

$sent9000   = ($lines | Where-Object { $_ -match "$ServerIP[:.]9000" -and $_ -match ">\s*$ServerIP|>.*$ServerIP" }).Count
$recv9000   = ($lines | Where-Object { $_ -match "$ServerIP[:.]9000\s*>" }).Count
$recv9001   = ($lines | Where-Object { $_ -match "$ServerIP[:.]9001\s*>" }).Count
$any9001    = ($lines | Where-Object { $_ -match "9001" }).Count
$anyServer  = ($lines | Where-Object { $_ -match [regex]::Escape($ServerIP) }).Count

Write-Host "`n=== RESULTS =========================================" -ForegroundColor Magenta
Write-Host ("  Total packet lines involving {0}: {1}" -f $ServerIP, $anyServer)
Write-Host ("  Packets FROM server port 9000 (login channel):  {0}" -f $recv9000)
Write-Host ("  Packets FROM server port 9001 (world channel):  {0}" -f $recv9001) -ForegroundColor Yellow
Write-Host ("  Any line mentioning 9001 at all:                {0}" -f $any9001)
Write-Host "=====================================================" -ForegroundColor Magenta

if ($recv9001 -gt 20) {
    Write-Host "`nVERDICT: world-channel packets ARE ARRIVING at this PC in volume." -ForegroundColor Green
    Write-Host "The network path is CLEAR. The blockage is on THIS machine after arrival" -ForegroundColor Green
    Write-Host "(client, Decal, or Windows discarding them). Hunt locally." -ForegroundColor Green
} elseif ($recv9001 -gt 0) {
    Write-Host "`nVERDICT: only a FEW 9001 packets arrived - early handshake got through," -ForegroundColor Yellow
    Write-Host "but the world-entry BURSTS are being lost in transit. Path problem." -ForegroundColor Yellow
} else {
    Write-Host "`nVERDICT: ZERO packets from server port 9001 arrived." -ForegroundColor Red
    Write-Host "The world channel is being blocked BEFORE this PC - router/ISP/path." -ForegroundColor Red
}

Write-Host "`nFull text capture saved: $Dir\cap.txt (share excerpts if needed)"
