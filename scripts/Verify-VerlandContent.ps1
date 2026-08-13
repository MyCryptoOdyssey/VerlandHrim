# ============================================================
#  Verify-VerlandContent.ps1
#  THE CONTENT INTEGRITY SCANNER - manifest-driven, one-command
#  scorecard proving all custom content is present and correct
#  in a given dat + database tier.
#
#  USAGE (local PowerShell):
#   Client dat + local DB (default):
#     powershell -ExecutionPolicy Bypass -File Verify-VerlandContent.ps1
#   Any dat:
#     ... -File Verify-VerlandContent.ps1 -Dat "C:\Games\AC-Stock\client_portal.dat"
#   Skip DB (dat-only, e.g. checking a patched stock client):
#     ... -File Verify-VerlandContent.ps1 -Dat "..." -SkipDb
# ============================================================
param(
    [string]$Dat = "C:\Games\Asheron's Call\client_portal.dat",
    [string]$MySql = "C:\Program Files\MariaDB 12.3\bin\mysql.exe",
    [string]$DbName = "ace_world",
    [switch]$SkipDb
)
$ErrorActionPreference = "SilentlyContinue"
$Gem = "C:\GemForge"

# ---------- THE MANIFEST (update when content changes!) ----------
# Custom dat entries: id -> md5 of source .rgba in C:\GemForge
$DatManifest = @{
    "0600F001" = "hue01"; "0600F002" = "hue02"; "0600F003" = "hue03"
    "0600F004" = "hue04"; "0600F005" = "hue05"; "0600F006" = "hue06"
    "0600F007" = "hue07"; "0600F008" = "hue08"; "0600F009" = "hue09"
    "0600F00A" = "wb"
}
# DB expectations: gem weenie icon DIDs
$DbIconMap = @{
    4100010 = 100724737; 4100011 = 100724738; 4100012 = 100724739
    4100013 = 100724740; 4100014 = 100724741; 4100015 = 100724742
    4100016 = 100724743; 4100017 = 100724744; 4100018 = 100724745
    4100019 = 100724746
}
$WorldStringCount = 83322   # ace_world integrity number (update on content change)
# -----------------------------------------------------------------

function OK($m){ Write-Host "  [PASS] $m" -ForegroundColor Green }
function BAD($m){ Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:fails++ }
$script:fails = 0

Write-Host "VERLAND CONTENT INTEGRITY SCAN" -ForegroundColor Magenta
Write-Host "  Dat: $Dat" -ForegroundColor Cyan

# --- Dat checks ---
Set-Location $Gem
$info = dotnet GemForge.dll info $Dat 2>&1
Write-Host "  $info" -ForegroundColor Cyan
foreach ($id in ($DatManifest.Keys | Sort-Object)) {
    $src = $DatManifest[$id]
    $r = dotnet GemForge.dll extract $Dat $id "scan_$id" 2>&1
    if ($r -match "MISS") { BAD "$id ABSENT from dat"; continue }
    $a = (Get-FileHash "$Gem\scan_$id.rgba" -Algorithm MD5).Hash
    $b = (Get-FileHash "$Gem\$src.rgba" -Algorithm MD5).Hash
    if ($a -eq $b) { OK "$id present + byte-correct" } else { BAD "$id present but WRONG BYTES" }
    Remove-Item "$Gem\scan_$id.*" -Force
}

# --- DB checks ---
if (-not $SkipDb) {
    Write-Host "  DB: $DbName (enter local DB root password)" -ForegroundColor Cyan
    $rows = & $MySql -u root -p $DbName -N -e "SELECT object_Id, value FROM weenie_properties_d_i_d WHERE type=8 AND object_Id BETWEEN 4100010 AND 4100019;" 2>$null
    $seen = @{}
    foreach ($line in $rows) { $p = $line -split "\s+"; if ($p.Count -ge 2) { $seen[[int]$p[0]] = [long]$p[1] } }
    foreach ($oid in ($DbIconMap.Keys | Sort-Object)) {
        if (-not $seen.ContainsKey($oid)) { BAD "weenie $oid missing icon row"; continue }
        if ($seen[$oid] -eq $DbIconMap[$oid]) { OK "weenie $oid -> correct icon" } else { BAD "weenie $oid -> WRONG icon ($($seen[$oid]))" }
    }
    $wc = & $MySql -u root -p $DbName -N -e "SELECT COUNT(*) FROM weenie_properties_string;" 2>$null
    if ("$wc".Trim() -eq "$WorldStringCount") { OK "world integrity: $wc strings" } else { BAD "world integrity: $wc (expected $WorldStringCount)" }
}

Write-Host ""
if ($script:fails -eq 0) { Write-Host "ALL GREEN - content certified on this tier" -ForegroundColor Green }
else { Write-Host "$($script:fails) FAILURE(S) - content damaged or missing on this tier" -ForegroundColor Red }
