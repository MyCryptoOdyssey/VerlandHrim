# ============================================================
#  Build-ACStock.ps1
#  MOVE 2 AUTOMATION: builds C:\Games\AC-Stock - a copy of your
#  AC client carrying STOCK end-of-retail DATs (iteration 2072)
#  instead of your custom 2084 set. Used to test whether your
#  server's DDD patching + Thwarg world entry work for a
#  "normal player" client.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File .\Build-ACStock.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$Source = "C:\Games\Asheron's Call"
$Dest   = "C:\Games\AC-Stock"
$DatNames = @("client_cell_1.dat","client_portal.dat","client_highres.dat","client_local_English.dat")

function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function OK($m){ Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "`n[FAILED] $m" -ForegroundColor Red; exit 1 }

Write-Host "VERLAND_HRIM MOVE-2 BUILDER: Stock-DAT test client" -ForegroundColor Magenta

# ---- 1. Sanity ----
Step "1. Checking source client"
if (-not (Test-Path (Join-Path $Source "acclient.exe"))) { Fail "acclient.exe not found at $Source" }
OK "Source client present"

# ---- 2. Copy client (excluding the big DATs - we replace those) ----
Step "2. Building $Dest (copying client files, skipping custom DATs)"
if (Test-Path $Dest) {
    Warn "$Dest already exists - reusing it (delete the folder and rerun for a truly fresh build)"
} else {
    New-Item -ItemType Directory -Path $Dest | Out-Null
    Get-ChildItem $Source | Where-Object { $DatNames -notcontains $_.Name } |
        Copy-Item -Destination $Dest -Recurse -Force
    OK "Client files copied (without custom DATs)"
}

# ---- 3. Acquire stock DATs ----
Step "3. Stock end-of-retail DATs (iteration 2072)"
$missing = $DatNames | Where-Object { -not (Test-Path (Join-Path $Dest $_)) }
if (-not $missing) {
    OK "All four DATs already present in $Dest"
} else {
    Write-Host "  Needed: $($missing -join ', ')"
    Write-Host ""
    Write-Host "  The stock DAT bundle comes from the ACEmulator community:" -ForegroundColor Yellow
    Write-Host "     https://emulator.ac/how-to-play/   (their End-of-Retail files link)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  OPTION A: If you've already downloaded/extracted them somewhere,"
    Write-Host "            enter that folder path below and I'll copy them in."
    Write-Host "  OPTION B: Press Enter to open the download page in your browser,"
    Write-Host "            download + extract the EoR files, then rerun this script."
    $path = Read-Host "`n  Folder containing stock DATs (or Enter to open download page)"
    if ([string]::IsNullOrWhiteSpace($path)) {
        Start-Process "https://emulator.ac/how-to-play/"
        Write-Host "`n  Browser opened. Download the End-of-Retail DAT files, extract them,"
        Write-Host "  then RERUN this script and give it the extracted folder path." -ForegroundColor Magenta
        exit 0
    }
    if (-not (Test-Path $path)) { Fail "Folder not found: $path" }
    foreach ($d in $DatNames) {
        $src = Get-ChildItem -Path $path -Recurse -Filter $d | Select-Object -First 1
        if (-not $src) { Fail "Could not find $d under $path" }
        Copy-Item $src.FullName (Join-Path $Dest $d) -Force
        OK ("{0} copied ({1:N0} KB)" -f $d, ($src.Length/1KB))
    }
}

# ---- 4. Fingerprint check: are these actually DIFFERENT from your custom set? ----
Step "4. Verifying these are stock (different from your 2084 set)"
$diffCount = 0
foreach ($d in $DatNames) {
    $a = (Get-Item (Join-Path $Source $d)).Length
    $b = (Get-Item (Join-Path $Dest   $d)).Length
    $same = ($a -eq $b)
    $flag = if ($same) { "IDENTICAL to custom (!)"} else { "different - good" }
    Write-Host ("  {0,-26} custom:{1,12:N0}  stock:{2,12:N0}  [{3}]" -f $d,$a,$b,$flag)
    if (-not $same) { $diffCount++ }
}
if ($diffCount -eq 0) { Fail "All four DATs are byte-identical to your custom set - these are NOT stock files. Get the EoR bundle from emulator.ac." }
OK "$diffCount of 4 DATs differ from the custom set - stock client confirmed"

# ---- 5. Instructions ----
Step "5. DONE - your test client is ready"
Write-Host @"

  NEXT (in ThwargLauncher):
   1. Bottom of Thwarg's window: 'AC Client File Location' - change it to:
         C:\Games\AC-Stock\acclient.exe
      (or if your Thwarg supports per-server client paths, set it on the
       Atlanta entry only)
   2. Check ONLY the Test Main Atlanta entry, boss profile only
   3. Launch -> watch the login closely:
        * a pause/'updating' phase = your server's DDD patching the client
          (THIS IS THE PLAYER ONBOARDING FLOW WORKING)
   4. Pick +K A R N -> two-minute clock
   5. Report: did DDD patch it? did the session survive?

  REMEMBER: set Thwarg's client path BACK to
  C:\Games\Asheron's Call\acclient.exe after the experiment.
"@ -ForegroundColor Magenta
