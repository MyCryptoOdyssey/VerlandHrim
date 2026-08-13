# ============================================================
#  Finish-ACStock.ps1
#  Runs AFTER you download the End-of-Retail zip from Mega.
#  Finds the zip in Downloads, extracts it, verifies the DATs
#  are genuinely STOCK (different from your custom set),
#  installs them into C:\Games\AC-Stock, and prints the
#  Thwarg experiment steps.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Finish-ACStock.ps1"
# ============================================================
$ErrorActionPreference = "Stop"
$Downloads = "$env:USERPROFILE\Downloads"
$Dest      = "C:\Games\AC-Stock"
$Custom    = "C:\Games\Asheron's Call"
$DatNames  = @("client_cell_1.dat","client_portal.dat","client_highres.dat","client_local_English.dat")

function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function OK($m){ Write-Host "  [OK] $m" -ForegroundColor Green }
function Fail($m){ Write-Host "`n[FAILED] $m" -ForegroundColor Red; exit 1 }

Write-Host "AC-STOCK FINISHER" -ForegroundColor Magenta

# ---- 1. Find the EoR zip (newest zip in Downloads that contains a DAT) ----
Step "1. Hunting for the downloaded End-of-Retail zip in Downloads"
$zips = Get-ChildItem $Downloads -Filter "*.zip" | Sort-Object LastWriteTime -Descending
if (-not $zips) { Fail "No .zip files in $Downloads. Download the EoR bundle from the Mega link first." }
$eorZip = $null
foreach ($z in $zips) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $arc = [IO.Compression.ZipFile]::OpenRead($z.FullName)
        $hasDat = $arc.Entries | Where-Object { $_.Name -eq "client_portal.dat" }
        $arc.Dispose()
        if ($hasDat) { $eorZip = $z; break }
    } catch { continue }
}
if (-not $eorZip) { Fail "No zip in Downloads contains client_portal.dat. Is the Mega download finished?" }
OK ("Found: {0} ({1:N0} MB, downloaded {2})" -f $eorZip.Name, ($eorZip.Length/1MB), $eorZip.LastWriteTime)

# ---- 2. Extract ----
Step "2. Extracting"
$tmp = Join-Path $env:TEMP "eor-extract"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $eorZip.FullName -DestinationPath $tmp -Force
OK "Extracted to temp"

# ---- 3. Fingerprint check: must DIFFER from custom set ----
Step "3. Fingerprint check (stock must differ from your custom 2084 set)"
$diff = 0
foreach ($d in $DatNames) {
    $src = Get-ChildItem $tmp -Recurse -Filter $d | Select-Object -First 1
    if (-not $src) { Fail "$d missing from the extracted bundle." }
    $stockKB  = [math]::Round($src.Length/1KB)
    $customKB = [math]::Round((Get-Item (Join-Path $Custom $d)).Length/1KB)
    $same = ($stockKB -eq $customKB)
    $tag = if ($same) { "identical (expected only for highres)" } else { "DIFFERENT - stock confirmed" }
    Write-Host ("  {0,-26} stock:{1,10:N0} KB   custom:{2,10:N0} KB   [{3}]" -f $d,$stockKB,$customKB,$tag)
    if (-not $same) { $diff++ }
}
if ($diff -eq 0) { Fail "Every DAT matches your custom set - this bundle is NOT stock. Something is wrong; stop and report." }
OK "$diff of 4 differ from custom - genuine stock files"

# ---- 4. Install into AC-Stock ----
Step "4. Installing stock DATs into $Dest"
if (-not (Test-Path (Join-Path $Dest "acclient.exe"))) { Fail "$Dest missing or incomplete - run Build-ACStock.ps1 first." }
foreach ($d in $DatNames) {
    $src = Get-ChildItem $tmp -Recurse -Filter $d | Select-Object -First 1
    Copy-Item $src.FullName (Join-Path $Dest $d) -Force
}
OK "Four stock DATs installed"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

# ---- 5. Marching orders ----
Step "5. READY - the experiment"
Write-Host @"

  IN THWARGLAUNCHER:
   1. Bottom field 'AC Client File Location' -> change to:
         C:\Games\AC-Stock\acclient.exe
   2. ONLY the Test Main Atlanta entry checked, boss profile only
   3. Launch. WATCH THE LOGIN:
        - a pause / patching phase = your server DDD-updating this
          'stock player' client  (this is your onboarding flow, live)
   4. Pick +K A R N -> TWO-MINUTE CLOCK
   5. Report BOTH: did it patch?  did it survive?

  AFTERWARD: set Thwarg's client path back to
      C:\Games\Asheron's Call\acclient.exe
"@ -ForegroundColor Magenta
