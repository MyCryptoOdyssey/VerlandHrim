# ============================================================
#  VH-Diag-1-ClientAudit.ps1
#  ANSWERS: How many AC clients do I have? Which DATs does each
#  carry? Which client does each ThwargLauncher entry launch?
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File .\VH-Diag-1-ClientAudit.ps1
# ============================================================
$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n=== VH DIAG 1: CLIENT & DAT AUDIT ===" -ForegroundColor Magenta

# ---- Find every acclient.exe on C: ----
Write-Host "`n[A] Scanning for AC client installs (takes a minute)..." -ForegroundColor Cyan
$clients = Get-ChildItem -Path C:\ -Recurse -Filter "acclient.exe" -File -ErrorAction SilentlyContinue
if (-not $clients) { Write-Host "  No acclient.exe found on C:\ !" -ForegroundColor Red }

# Known fingerprints (KB sizes) for comparison
$serverDats = @{
    "client_portal.dat"        = 905216   # YOUR custom set (iteration 2084) as uploaded to Atlanta
    "client_cell_1.dat"        = 339968
    "client_highres.dat"       = 130048
    "client_local_English.dat" = 1024
}

foreach ($c in $clients) {
    $dir = $c.DirectoryName
    Write-Host "`n  CLIENT: $dir" -ForegroundColor Green
    Write-Host  "    acclient.exe modified: $($c.LastWriteTime)"
    $decal = Test-Path (Join-Path $dir "Decal.dll")
    Write-Host  "    Decal.dll present in folder: $decal"
    $verdictParts = @()
    foreach ($dat in $serverDats.Keys) {
        $f = Get-Item (Join-Path $dir $dat)
        if ($f) {
            $kb = [math]::Round($f.Length / 1KB)
            $match = if ($kb -eq $serverDats[$dat]) { "MATCHES server/custom set" } else { "DIFFERENT from server set" }
            Write-Host ("    {0,-26} {1,10:N0} KB  [{2}]" -f $dat, $kb, $match)
            $verdictParts += ($kb -eq $serverDats[$dat])
        } else {
            Write-Host ("    {0,-26} MISSING" -f $dat) -ForegroundColor Yellow
        }
    }
    if ($verdictParts -and ($verdictParts -notcontains $false)) {
        Write-Host "    >>> VERDICT: this client carries the CUSTOM (2084) DAT set - Verland-compatible, will be BOOTED by stock servers" -ForegroundColor Yellow
    } elseif ($verdictParts) {
        Write-Host "    >>> VERDICT: this client carries a DIFFERENT DAT set (likely stock/end-of-retail)" -ForegroundColor Cyan
    }
}

# ---- ThwargLauncher: map entries to client paths ----
Write-Host "`n[B] Reading ThwargLauncher configuration..." -ForegroundColor Cyan
$thwargRoots = @(
    "$env:APPDATA\ThwargLauncher",
    "$env:LOCALAPPDATA\ThwargLauncher",
    "$env:USERPROFILE\Documents\ThwargLauncher"
)
$foundThwarg = $false
foreach ($root in $thwargRoots) {
    if (-not (Test-Path $root)) { continue }
    $foundThwarg = $true
    Write-Host "  Config folder: $root"
    $files = Get-ChildItem $root -Recurse -Include "*.xml","*.txt","*.config" -File
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw
        if ($content -match "45\.76\.62\.139|100\.119\.34\.106|9000|acclient") {
            Write-Host "`n  --- $($f.Name) (relevant excerpts) ---" -ForegroundColor Green
            # Print lines mentioning servers or client paths
            Get-Content $f.FullName | Where-Object {
                $_ -match "45\.76|100\.119|127\.0\.0\.1|ServerName|acclient|ClientPath|Address|Port"
            } | ForEach-Object { Write-Host "    $($_.Trim())" }
        }
    }
}
if (-not $foundThwarg) { Write-Host "  ThwargLauncher config folder not found in usual spots." -ForegroundColor Yellow }

Write-Host "`n=== KEY QUESTIONS THIS ANSWERS ===" -ForegroundColor Magenta
Write-Host " 1. Do I have ONE client or SEVERAL?"
Write-Host " 2. Which DAT set does each carry (custom 2084 vs stock)?"
Write-Host " 3. Which client path do my Thwarg entries point at?"
Write-Host "Paste the full output back for analysis." -ForegroundColor Magenta
