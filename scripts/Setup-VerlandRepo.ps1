# ============================================================
#  Setup-VerlandRepo.ps1
#  Builds C:\VerlandHrim\ with the repo-ready structure,
#  a README, a .gitignore (secrets + binaries excluded),
#  and consolidates your script library into scripts\.
#
#  RUN (normal PowerShell):
#  powershell -ExecutionPolicy Bypass -File "C:\Users\KRIEG\Downloads\Setup-VerlandRepo.ps1"
# ============================================================
$ErrorActionPreference = "SilentlyContinue"
$Root = "C:\VerlandHrim"

function OK($m){ Write-Host "  [OK] $m" -ForegroundColor Green }
Write-Host "VERLAND REPO STARTER" -ForegroundColor Magenta

# ---- Structure ----
foreach ($d in @("docs","scripts","content","backups")) {
    New-Item -ItemType Directory -Path (Join-Path $Root $d) -Force | Out-Null
}
OK "Structure: $Root\{docs, scripts, content, backups}"

# ---- README ----
@"
# Verland_Hrim
Private operations repository for the Verland_Hrim Asheron's Call shard.

## What lives here
- **docs/** - operations doctrine, setup guide, investigation dossiers,
  post-mortems. The doctrine is the master reference.
- **scripts/** - the complete ops & diagnostic tool library (PowerShell
  for the Windows side, bash for the server side).
- **content/** - custom content workspace: SQL deltas, GemForge/SpellForge
  exports, content change log.
- **backups/** - periodic offsite copies of server database dumps
  (large files; committed sparingly).

## What NEVER lives here
- Passwords, keys, credentials of any kind (keyring lives elsewhere)
- DAT files (900MB binaries - covered by snapshots + local masters)

## The server
Production: Vultr, Atlanta - WorldName ``Verland_Hrim``
See docs/VerlandHrim_Operations_Doctrine.md for everything.

## Rule 14
A ThwargLauncher entry's name must be byte-identical to the server's
WorldName, or the launcher silently kills the client. This cost two days
to learn. It is not negotiable.
"@ | Set-Content (Join-Path $Root "README.md")
OK "README.md written"

# ---- .gitignore ----
@"
# Secrets - never committed
*password*
*credential*
*.key
*keyring*

# Big binaries - covered by other backup tiers
*.dat
*.zip
*.etl

# Noise
Thumbs.db
desktop.ini
*.tmp
"@ | Set-Content (Join-Path $Root ".gitignore")
OK ".gitignore written (secrets + binaries excluded)"

# ---- Consolidate the script library ----
$found = 0
$patterns = @("*.ps1","*.sh")
$sources = @("$env:USERPROFILE\Downloads", [Environment]::GetFolderPath("Desktop"))
$known = @("stage-verland-hrim","Find-LocalAceVersion","VH-Diag","vh-diag","Make-VH-Launchers",
           "Build-ACStock","Finish-ACStock","Assemble-ACStock","Check-DatLineage",
           "Verify-PatchAndRetry","Watch-WhichClient","Audit-VerlandBackups",
           "install-ace-stable","build-vanilla-twin","fix-vanilla-twin","restore-both-worlds",
           "phase1","phase2","phase3","phase4","warm-entry","ops-automation","Setup-VerlandRepo")
foreach ($src in $sources) {
    foreach ($pat in $patterns) {
        Get-ChildItem $src -Filter $pat -File | ForEach-Object {
            $name = $_.BaseName
            if ($known | Where-Object { $name -like "$_*" }) {
                Copy-Item $_.FullName (Join-Path $Root "scripts\") -Force
                $found++
            }
        }
    }
}
OK "Script library consolidated: $found tool(s) copied to scripts\ (originals left in place)"

# ---- Docs reminder ----
$doc = "$env:USERPROFILE\Downloads\VerlandHrim_Operations_Doctrine.md"
if (Test-Path $doc) {
    Copy-Item $doc (Join-Path $Root "docs\") -Force
    OK "Operations Doctrine copied into docs\"
} else {
    Write-Host "  [i] Doctrine not found in Downloads - download it from chat, drop into docs\" -ForegroundColor Yellow
}
$dossier = "$env:USERPROFILE\Downloads\VerlandHrim_Dossier.md"
if (Test-Path $dossier) {
    Copy-Item $dossier (Join-Path $Root "docs\") -Force
    OK "Investigation dossier copied into docs\"
}

Write-Host ""
Write-Host "READY FOR GITHUB - next steps in chat." -ForegroundColor Magenta
