# Verland_Hrim — Session Handoff · Aug 12, 2026 (evening)

## CURRENT STATE: ALL SYSTEMS GREEN
- **Production:** Vultr 155.138.215.4 ("verlandhrimace"), WorldName `Verland_Hrim`,
  ACE Docker (digest-pinned), MariaDB 12.3, DDD ON, 6 sessions/IP,
  self-healing restarts, 3AM backups (keep 7), Fri 2PM maintenance cron,
  3306 localhost-only. Snapshots: `vanilla-works`, `verland-live` (crown state).
- **Local:** Prod C:\ACE (:9000) + Test C:\ACE-Test (:9002), MariaDB 12.3.
- **Client master:** C:\Games\Asheron's Call — portal **iteration 2105**.
  All tiers (client / Local Prod / Local Test / Atlanta) aligned at 2105,
  gems verified rendering on ALL THREE worlds by login.
- **GEM SAGA: SOLVED.** Three root causes, all fixed:
  1. Icon IDs >0xFFFF unreachable (16-bit window) → relocated to 0x0600F001-F00A
  2. DDD ships hollow patches unless per-entry Iteration stamped → stamped 2104
  3. ACE DDD dat-writes structurally defective (client misreads) → OPEN BUG,
     evidence preserved: C:\Games\AC-Stock\client_portal.dat.DDD.bak
     (interim policy: players get pre-built portal.dat as download)
- **Content cards corrected at source:** 03_PortalGemVendor.sql (both
  C:\ACE and C:\ACE-Test Content trees) now carry 100724737-46. ACE
  re-applies Content SQL on every boot — cards are the source of truth.
- **Governance live:** Promotion Protocol (Author→Test→LocalProd→Atlanta,
  THE LAP between stages) + Verify-VerlandContent.ps1 scanner (manifest-
  driven; caught real drift on first run). Last scan: ALL GREEN.
- **Repo:** private GitHub MyCryptoOdyssey/VerlandHrim, ~60 files: docs,
  scripts (34 tools), content cards, tools (GemForge+DatForensics WITH
  DatForensics source in tools\src), client-configs (3 custom Decal
  plugins: DerethWatch/LeakWatch/TestBanner + 3 Society VTank metas).
  Note: repo .git was relocated from nested folder — healthy now.

## CREDENTIALS MAP (values in Glenn's Notepad keyring)
- #1 Local MariaDB root · Vultr clean-box SSH root · Clean-box DB:
  root='VanillaRootPass' user='VanillaUserPass' (Glenn used the literal
  examples; on record with his OK) · GitHub account: MyCryptoOdyssey

## KEY RULES (hard-won)
- **Rule 14:** Thwarg entry name must equal WorldName byte-exactly or the
  launcher kills the client ~1min in. Corollary: identical WorldNames
  share one Thwarg session slot per account (Prod+Atlanta both
  `Verland_Hrim` = can't dual-log same account; different account works).
- Iterations must match client↔server exactly (drift = boot). Sync after
  every dat write. Server/local-server STOPPED before writing its dat.
- Dat deploys: ship surgery not file (gemkit pattern). Verify
  FUNCTIONALLY (per-entry extract+hash), never whole-file hash (dat
  container isn't byte-deterministic).
- Thwarg's client-path field silently reverts — verify by launching.
- AC client must launch from its own folder (cd first) or "can't open
  data files".
- Client-rendered truth is the only truth; every tool can pass while the
  1999 client fails.

## PENDING DOCKET (next sessions)
1. **Discord setup** (item 7, the finale — Glenn wants it as its own
   session): server structure, join post (name exactly Verland_Hrim,
   emulator.ac bundle + pre-built portal.dat download, 6/IP, Fri 2PM CT),
   UptimeRobot Discord webhook (email-only monitor may exist by then;
   webhook is 5-min add-on), decision: public tools repo
   (VerlandHrim-Community — DatForensics+source, Rule-14/DDD findings).
2. **UptimeRobot** ping monitor 155.138.215.4 (email) — may be done.
3. **Day's ledger doc** — the Aug 11-12 accounting for docs\.
4. **DDD block-write investigation** — add `chain` verb to DatForensics
   (source in repo tools\src; sandbox build pattern: dotnet-sdk-8.0,
   NuGet.config with cleared sources, reference DatReaderWriter.dll),
   diff defective specimen vs surgical file, then ACE bug report.
5. **Rare-drop verification** — Glenn testing in-game tonight; findings
   may spawn content work.
6. **Doctrine amendments** — merge tonight's rules into Operations
   Doctrine; update Known-Good ledger (iteration 2105, scanner manifest).
7. Someday: report Rule 14 + DDD findings to Thwarg/ACE communities
   (dossier exists, needs refresh).

## KEY PATHS
- Repo C:\VerlandHrim · GemForge C:\GemForge (+forensics\) · Scanner:
  C:\VerlandHrim\scripts\Verify-VerlandContent.ps1 · Cards:
  C:\ACE\Content\Sql\VerlandHrim\ · Atlanta scripts in /root/, kit in
  /root/gemkit2/ · Backups: every *.bak beside its original
- Atlanta ops: cd /root/vanilla-ace; docker compose {stop|start|restart}
  ace-server; docker logs ace-server

## GLENN'S WORKFLOW NOTES
- File cards render at TOP of Claude messages — always end delivery
  messages with "SCROLL UP, CLICK THE CARD" (protocol adopted after 5
  misses). Two sources: chat cards (Claude-built) vs Downloads
  (Glenn-built via commands) — name which.
- Window discipline: PS C:\ = local; root@verlandhrimace = Atlanta.
  Deliberate numbered steps; one question at a time; scripts over
  command-chains for anything multi-step.
