# ============================================================
#  Verland_Hrim Migration Stager  (Part 0 automation)
#  Dumps ace_auth / ace_shard / ace_world, gathers Dats + Content
#  into C:\ace-migration, and verifies everything looks healthy.
#
#  HOW TO RUN:
#    1. Close your ACE server (log characters out first)
#    2. Open PowerShell
#    3. powershell -ExecutionPolicy Bypass -File C:\path\to\stage-verland-hrim.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ---------- Settings (edit if your paths differ) ----------
$MysqldumpExe = "C:\Program Files\MariaDB 12.3\bin\mysqldump.exe"
$StageDir     = "C:\ace-migration"
$DbUser       = "root"
$Databases    = @("ace_auth", "ace_shard", "ace_world")
# -----------------------------------------------------------

function Write-Step($msg)  { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Good($msg)  { Write-Host "  [OK] $msg"    -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  [!!] $msg"    -ForegroundColor Yellow }
function Fail($msg)        { Write-Host "`n[FAILED] $msg" -ForegroundColor Red; exit 1 }

Write-Host "Verland_Hrim Migration Stager" -ForegroundColor Magenta
Write-Host "-----------------------------"

# ---- Pre-flight checks ----
Write-Step "Pre-flight checks"

if (-not (Test-Path $MysqldumpExe)) {
    Fail "mysqldump not found at: $MysqldumpExe`nEdit the `$MysqldumpExe line at the top of this script."
}
Write-Good "Found mysqldump ($MysqldumpExe)"

if (Get-Process -Name "ACE.Server" -ErrorAction SilentlyContinue) {
    Write-Warn2 "ACE.Server appears to be RUNNING. Dumps should be taken with the server stopped."
    $answer = Read-Host "  Continue anyway? (y/N)"
    if ($answer -ne "y") { Fail "Stopped by user. Close the ACE server and run again." }
} else {
    Write-Good "ACE server is not running (good - clean dump)"
}

New-Item -ItemType Directory -Path $StageDir -Force | Out-Null
Write-Good "Staging folder ready: $StageDir"

# ---- Database password (asked once, hidden) ----
Write-Step "Database credentials"
$SecurePw = Read-Host "  Enter MariaDB '$DbUser' password" -AsSecureString
$Bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePw)
$PlainPw = [Runtime.InteropServices.Marshal]::PtrToStringAuto($Bstr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Bstr)

# MYSQL_PWD env var: password never appears on the command line
$env:MYSQL_PWD = $PlainPw

# ---- Dump the three databases ----
Write-Step "Dumping databases (ace_world is big - be patient)"

foreach ($db in $Databases) {
    $outFile = Join-Path $StageDir "$db.sql"
    Write-Host "  Dumping $db ..." -NoNewline
    # --result-file writes the file directly = correct encoding guaranteed
    & $MysqldumpExe -u $DbUser --result-file="$outFile" $db
    if ($LASTEXITCODE -ne 0) {
        $env:MYSQL_PWD = $null
        Fail "mysqldump returned an error for '$db'. Check the password and database name."
    }
    $sizeKB = [math]::Round((Get-Item $outFile).Length / 1KB)
    Write-Host " done ($sizeKB KB)" -ForegroundColor Green
}

$env:MYSQL_PWD = $null   # scrub password from environment

# ---- Sanity-check dump sizes ----
Write-Step "Sanity-checking dumps"
$worldSize = (Get-Item (Join-Path $StageDir "ace_world.sql")).Length
if ($worldSize -lt 10MB) {
    Write-Warn2 "ace_world.sql is under 10 MB - that is suspiciously small. Verify before migrating."
} else {
    Write-Good ("ace_world.sql looks healthy ({0:N0} MB)" -f ($worldSize / 1MB))
}
foreach ($db in @("ace_auth","ace_shard")) {
    $f = Get-Item (Join-Path $StageDir "$db.sql")
    if ($f.Length -eq 0) { Write-Warn2 "$db.sql is EMPTY - dump failed silently." }
    else { Write-Good ("{0}.sql present ({1:N0} KB)" -f $db, ($f.Length / 1KB)) }
}

# ---- Locate and copy DAT files ----
Write-Step "DAT files"
$DatGuesses = @(
    "C:\Turbine\Asheron's Call",
    "C:\Games\AC",
    "C:\ACE\Dats",
    "$env:USERPROFILE\Desktop\ACE\Dats"
)
$DatSource = $null
foreach ($guess in $DatGuesses) {
    if (Test-Path (Join-Path $guess "client_portal.dat")) { $DatSource = $guess; break }
}
if (-not $DatSource) {
    Write-Warn2 "Could not auto-find the DAT files."
    Write-Host  "  (Hint: your ACE Config.js 'DatFilesDirectory' line says where they are.)"
    $DatSource = Read-Host "  Enter the folder containing client_portal.dat (or press Enter to skip)"
}
if ($DatSource -and (Test-Path (Join-Path $DatSource "client_portal.dat"))) {
    $DatDest = Join-Path $StageDir "Dats"
    New-Item -ItemType Directory -Path $DatDest -Force | Out-Null
    Write-Host "  Copying DATs from $DatSource (several GB - this is the slow part)..."
    Copy-Item -Path (Join-Path $DatSource "client_*.dat") -Destination $DatDest -Force
    $datCount = (Get-ChildItem $DatDest -Filter "client_*.dat").Count
    $datGB = [math]::Round(((Get-ChildItem $DatDest | Measure-Object Length -Sum).Sum / 1GB), 2)
    Write-Good "$datCount DAT files staged ($datGB GB)"
} else {
    Write-Warn2 "DATs skipped - stage them manually into $StageDir\Dats before migrating."
}

# ---- Content folder (only if it exists and has files) ----
Write-Step "Custom Content folder"
$ContentGuesses = @("C:\ACE\Content", "$env:USERPROFILE\Desktop\ACE\Content")
$ContentSource = $null
foreach ($guess in $ContentGuesses) {
    if ((Test-Path $guess) -and (Get-ChildItem $guess -Recurse -File -ErrorAction SilentlyContinue)) {
        $ContentSource = $guess; break
    }
}
if (-not $ContentSource) {
    $answer = Read-Host "  No Content folder auto-found. Enter its path, or press Enter if your content lives in the database (most common)"
    if ($answer -and (Test-Path $answer)) { $ContentSource = $answer }
}
if ($ContentSource) {
    Copy-Item -Path $ContentSource -Destination (Join-Path $StageDir "Content") -Recurse -Force
    Write-Good "Content folder staged from $ContentSource"
} else {
    Write-Good "No file-based content - your custom work is inside ace_world.sql (normal)"
}

# ---- Final report ----
Write-Step "Staging complete - contents of $StageDir"
Get-ChildItem $StageDir -Recurse -File |
    Select-Object @{n="File";e={$_.FullName.Replace("$StageDir\","")}},
                  @{n="Size";e={ if ($_.Length -gt 1GB) {"{0:N2} GB" -f ($_.Length/1GB)}
                                 elseif ($_.Length -gt 1MB) {"{0:N1} MB" -f ($_.Length/1MB)}
                                 else {"{0:N0} KB" -f ($_.Length/1KB)} }} |
    Format-Table -AutoSize

Write-Host "This folder is now everything Atlanta needs." -ForegroundColor Magenta
Write-Host "Your local server is free to restart - the photograph is taken." -ForegroundColor Magenta
