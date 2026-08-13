# ============================================================
#  Audit-VerlandBackups.ps1
#  Answers: where do complete copies of Verland's soul exist
#  RIGHT NOW on this PC? Checks staging, masters, and dumps.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Audit-VerlandBackups.ps1"
# ============================================================
$ErrorActionPreference = "SilentlyContinue"
function H($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function OK($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function MISS($m){ Write-Host "  [MISS] $m" -ForegroundColor Red }
function INFO($m){ Write-Host "  [i]    $m" -ForegroundColor Yellow }

Write-Host "VERLAND BACKUP AUDIT - $(Get-Date)" -ForegroundColor Magenta

H "1. Staging folder C:\ace-migration (post-WinSCP-moves)"
$stage = "C:\ace-migration"
foreach ($f in @("ace_auth.sql","ace_shard.sql","ace_world.sql")) {
    $p = Join-Path $stage $f
    if (Test-Path $p) { OK ("{0}  ({1:N0} KB, {2})" -f $f, ((Get-Item $p).Length/1KB), (Get-Item $p).LastWriteTime) }
    else { MISS "$f gone from staging" }
}
foreach ($d in @("client_cell_1.dat","client_portal.dat","client_highres.dat","client_local_English.dat")) {
    $p = Join-Path "$stage\Dats" $d
    if (Test-Path $p) { OK ("Dats\{0}  ({1:N0} KB)" -f $d, ((Get-Item $p).Length/1KB)) }
    else { MISS "Dats\$d gone from staging (WinSCP move suspect)" }
}
if (Test-Path "$stage\Content") {
    $cc = (Get-ChildItem "$stage\Content" -Recurse -File).Count
    OK "Content folder staged ($cc files)"
} else { MISS "Content folder not in staging" }

H "2. MASTER copies (the originals staging was built from)"
foreach ($d in @("client_cell_1.dat","client_portal.dat","client_highres.dat","client_local_English.dat")) {
    $p = "C:\Games\Asheron's Call\$d"
    if (Test-Path $p) { OK ("Master DAT: {0} ({1:N0} KB)" -f $d, ((Get-Item $p).Length/1KB)) }
    else { MISS "Master DAT missing: $d" }
}
$aceContent = Get-ChildItem "C:\ACE\Content" -Recurse -File -ErrorAction SilentlyContinue
if ($aceContent) { OK "C:\ACE\Content master present ($($aceContent.Count) files - your dev workspace)" }
else { INFO "C:\ACE\Content not found at that path - if your ACE folder is elsewhere, check manually" }

H "3. LIVE database (the ultimate master - can re-dump anytime)"
$mysqldump = "C:\Program Files\MariaDB 12.3\bin\mysqldump.exe"
if (Test-Path $mysqldump) { OK "Local MariaDB 12.3 present - fresh dumps available on demand (stage-verland-hrim.ps1)" }
else { INFO "mysqldump not at expected path - local DB may have moved" }

H "4. VERDICT"
Write-Host @"
  Recovery-critical items and their redundancy:
   - World/shard/auth SQL: staging copies (above) + /root/*.sql on the
     Atlanta server + re-dumpable from local MariaDB anytime
   - DATs: staging copies + masters in C:\Games\Asheron's Call
   - Content dev workspace: C:\ACE\Content (masters)
  ANY [MISS] above that lacks a green counterpart elsewhere = copy it
  before the server wipe. All green somewhere = safe to proceed.
"@ -ForegroundColor Magenta
