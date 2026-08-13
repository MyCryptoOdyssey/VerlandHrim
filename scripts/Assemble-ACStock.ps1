# ============================================================
#  Assemble-ACStock.ps1
#  FINAL ASSEMBLY: builds the stock-player test client using
#  the stock portal.dat from the downloaded bundle plus your
#  three unmodified DATs. Verifies by hash that AC-Stock's
#  portal DIFFERS from your custom one before declaring ready.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Assemble-ACStock.ps1"
# ============================================================
$ErrorActionPreference = "Stop"
$Downloads = "$env:USERPROFILE\Downloads"
$Custom    = "C:\Games\Asheron's Call"
$Dest      = "C:\Games\AC-Stock"

function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function OK($m){ Write-Host "  [OK] $m" -ForegroundColor Green }
function Fail($m){ Write-Host "`n[FAILED] $m" -ForegroundColor Red; exit 1 }

Write-Host "AC-STOCK FINAL ASSEMBLY" -ForegroundColor Magenta

# ---- 1. Prereqs ----
Step "1. Checking pieces"
if (-not (Test-Path (Join-Path $Dest "acclient.exe"))) { Fail "$Dest incomplete - run Build-ACStock.ps1 first." }
$zip = Get-ChildItem $Downloads -Filter "ac-updates*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $zip) { Fail "ac-updates zip not found in Downloads." }
OK "AC-Stock client shell present; bundle: $($zip.Name)"

# ---- 2. Extract bundle, pull the STOCK portal ----
Step "2. Extracting stock portal.dat from bundle"
$tmp = Join-Path $env:TEMP "assemble-extract"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $zip.FullName -DestinationPath $tmp -Force
$stockPortal = Get-ChildItem $tmp -Recurse -Filter "client_portal.dat" | Select-Object -First 1
if (-not $stockPortal) { Fail "portal.dat not in bundle?!" }
Copy-Item $stockPortal.FullName (Join-Path $Dest "client_portal.dat") -Force
OK "Stock portal.dat installed into AC-Stock"

# ---- 3. The other three from your client (verified unmodified) ----
Step "3. Installing the three unmodified DATs from your client"
foreach ($d in @("client_cell_1.dat","client_local_English.dat","client_highres.dat")) {
    Copy-Item (Join-Path $Custom $d) (Join-Path $Dest $d) -Force
    OK "$d copied"
}
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

# ---- 4. Hash verification: AC-Stock portal MUST differ from custom ----
Step "4. Verification (hashing - takes a minute)"
$hStock  = (Get-FileHash (Join-Path $Dest   "client_portal.dat") -Algorithm MD5).Hash
$hCustom = (Get-FileHash (Join-Path $Custom "client_portal.dat") -Algorithm MD5).Hash
Write-Host "  AC-Stock portal: $($hStock.Substring(0,12))..."
Write-Host "  Custom  portal:  $($hCustom.Substring(0,12))..."
if ($hStock -eq $hCustom) { Fail "Portal dats are IDENTICAL - assembly grabbed the wrong file. Stop and report." }
OK "AC-Stock portal is genuinely STOCK (differs from custom)"

# ---- 5. Marching orders ----
Step "5. READY - THE EXPERIMENT"
Write-Host @"

  This client is now 'a brand-new player who followed emulator.ac':
  stock portal 2072, standard everything.

  IN THWARGLAUNCHER:
   1. 'AC Client File Location' (bottom) -> C:\Games\AC-Stock\acclient.exe
   2. ONLY Test Main Atlanta checked, boss profile only
   3. Launch. WATCH THE LOGIN CLOSELY:
        - a pause / patch phase = your server DDD-updating this client's
          portal.dat from 2072 to 2084  (YOUR PLAYER ONBOARDING, LIVE)
   4. +K A R N -> TWO-MINUTE CLOCK
   5. Report BOTH: did it patch?  did it survive?

  AFTERWARD: Thwarg client path back to C:\Games\Asheron's Call\acclient.exe
"@ -ForegroundColor Magenta
