# ============================================================
#  Verify-PatchAndRetry.ps1
#  TWO JOBS:
#   1. PROOF: did your Atlanta server patch AC-Stock's portal.dat
#      from stock (2C89662A...) to your custom 2084 (A8AB6330...)?
#   2. Prints the exact Thwarg retry-test steps for the
#      freshly-patched client.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Verify-PatchAndRetry.ps1"
# ============================================================
$ErrorActionPreference = "Stop"

$StockHashBefore = "2C89662A44FC"   # first 12 chars, from the assembly run
$CustomHash      = "A8AB63303523"   # first 12 chars, your live custom portal

function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }

Write-Host "PATCH VERIFICATION + RETRY BRIEFING" -ForegroundColor Magenta

Step "1. Hashing AC-Stock's portal.dat (takes a minute)"
$f = "C:\Games\AC-Stock\client_portal.dat"
if (-not (Test-Path $f)) { Write-Host "[FAILED] $f not found" -ForegroundColor Red; exit 1 }
$h = (Get-FileHash $f -Algorithm MD5).Hash
$size = [math]::Round((Get-Item $f).Length/1KB)
Write-Host ("  Current hash: {0}...   Size: {1:N0} KB" -f $h.Substring(0,12), $size)

Step "2. VERDICT"
if ($h.StartsWith($CustomHash)) {
    Write-Host "  MATCHES YOUR CUSTOM PORTAL." -ForegroundColor Green
    Write-Host ""
    Write-Host "  PROOF: your Atlanta server's DDDManager patched this stock" -ForegroundColor Magenta
    Write-Host "  client's portal.dat into a byte-perfect copy of your custom" -ForegroundColor Magenta
    Write-Host "  2084 file during that login. PLAYER ONBOARDING: FUNCTIONAL." -ForegroundColor Magenta
} elseif ($h.StartsWith($StockHashBefore)) {
    Write-Host "  STILL STOCK - unchanged." -ForegroundColor Yellow
    Write-Host "  The server did not patch it (or patching didn't complete)." -ForegroundColor Yellow
    Write-Host "  The Coldeve 'newer than expected' boot then needs another look." -ForegroundColor Yellow
} else {
    Write-Host "  DIFFERENT FROM BOTH ($($h.Substring(0,12))...)" -ForegroundColor Yellow
    Write-Host "  Partially patched or a different iteration - paste this back." -ForegroundColor Yellow
}

Step "3. THE RETRY TEST (do this now, by hand - 2 minutes)"
Write-Host @"

  IN THWARGLAUNCHER:
   1. 'AC Client File Location' still ->  C:\Games\AC-Stock\acclient.exe
   2. Check ONLY 'Test Main Atlanta' (uncheck Coldeve), boss profile only
   3. Launch -> pick +K A R N
   4. TWO-MINUTE CLOCK - walk, jump, open your pack

  WHY: the client now carries the server-patched 2084 portal.
  If this morning's disconnect was the PATCH CYCLE completing
  (not the timeout bug), this login should simply... hold.

  REPORT: survived past two minutes -> YES or NO
"@ -ForegroundColor Magenta

Step "4. OPTIONAL server-side receipt (paste on the SSH window)"
Write-Host '  journalctl -u ace --no-pager | grep -iE "DDD|patch|Interrogation" | tail -8'
