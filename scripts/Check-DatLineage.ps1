# ============================================================
#  Check-DatLineage.ps1
#  ANSWERS ONE QUESTION: is the ac-updates zip you just
#  downloaded from the emulator.ac link byte-identical to the
#  DATs your client/server already run?
#  (If YES: the public download IS your 2084 lineage - the
#   mismatch with Coldeve/Buadren was never your doing.)
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Check-DatLineage.ps1"
# ============================================================
$ErrorActionPreference = "Stop"
$Downloads = "$env:USERPROFILE\Downloads"
$Custom    = "C:\Games\Asheron's Call"

function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function OK($m){ Write-Host "  [OK] $m" -ForegroundColor Green }
function Fail($m){ Write-Host "`n[FAILED] $m" -ForegroundColor Red; exit 1 }

Write-Host "DAT LINEAGE CHECK" -ForegroundColor Magenta

# ---- 1. Find the ac-updates zip (newest one) ----
Step "1. Locating the downloaded bundle"
$zip = Get-ChildItem $Downloads -Filter "ac-updates*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $zip) { Fail "No ac-updates*.zip found in Downloads." }
OK ("Using: {0} ({1:N0} MB, {2})" -f $zip.Name, ($zip.Length/1MB), $zip.LastWriteTime)

# ---- 2. Extract fresh ----
Step "2. Extracting"
$tmp = Join-Path $env:TEMP "lineage-extract"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $zip.FullName -DestinationPath $tmp -Force
$found = Get-ChildItem $tmp -Recurse -Filter "client_*.dat"
if (-not $found) { Fail "No client_*.dat files inside the zip." }
OK ("Bundle contains: {0}" -f (($found | ForEach-Object Name) -join ', '))

# ---- 3. Hash comparison against your live client DATs ----
Step "3. MD5 comparison: bundle vs your live custom DATs"
$verdictSame = 0; $verdictDiff = 0; $compared = 0
foreach ($f in $found) {
    $livePath = Join-Path $Custom $f.Name
    if (-not (Test-Path $livePath)) {
        Write-Host ("  {0,-26} (no live counterpart - skipped)" -f $f.Name) -ForegroundColor Yellow
        continue
    }
    Write-Host ("  Hashing {0} (big files take a moment)..." -f $f.Name)
    $hBundle = (Get-FileHash $f.FullName -Algorithm MD5).Hash
    $hLive   = (Get-FileHash $livePath  -Algorithm MD5).Hash
    $compared++
    if ($hBundle -eq $hLive) {
        Write-Host ("    IDENTICAL   bundle == live   [{0}]" -f $hBundle.Substring(0,12)) -ForegroundColor Green
        $verdictSame++
    } else {
        Write-Host ("    DIFFERENT   bundle {0}... vs live {1}..." -f $hBundle.Substring(0,12), $hLive.Substring(0,12)) -ForegroundColor Yellow
        $verdictDiff++
    }
}
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

# ---- 4. Verdict ----
Step "4. VERDICT"
if ($compared -eq 0) { Fail "Nothing comparable found." }
if ($verdictDiff -eq 0) {
    Write-Host "  ALL compared DATs are BYTE-IDENTICAL to your live set." -ForegroundColor Green
    Write-Host ""
    Write-Host "  MEANING: the public emulator.ac download IS your DAT lineage." -ForegroundColor Magenta
    Write-Host "  Your 'custom 2084' DATs are the community-distributed set -" -ForegroundColor Magenta
    Write-Host "  the version mismatch with Coldeve/Buadren was never your doing," -ForegroundColor Magenta
    Write-Host "  and your server runs the same DATs new players will download." -ForegroundColor Magenta
} elseif ($verdictSame -eq 0) {
    Write-Host "  ALL compared DATs DIFFER from your live set." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  MEANING: this bundle is a different lineage than your client -" -ForegroundColor Magenta
    Write-Host "  your live DATs were modified locally after all. The bundle can" -ForegroundColor Magenta
    Write-Host "  serve as the 'stock player' test set for the Move-2 experiment." -ForegroundColor Magenta
} else {
    Write-Host ("  MIXED: {0} identical, {1} different." -f $verdictSame,$verdictDiff) -ForegroundColor Yellow
    Write-Host "  Paste this output back for analysis - the split tells a story." -ForegroundColor Magenta
}
