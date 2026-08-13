# Verland_Hrim — Content Promotion Protocol
### The formal pipeline · v1.0 · August 2026

## THE PIPELINE
```
[1] AUTHOR      Content built with tools (GemForge/SQL) on workstation
[2] LOCAL TEST  Applied to Test server (C:\ACE-Test + test DB) -> LAP
[3] LOCAL PROD  Promoted to Local Prod (C:\ACE + local DB)     -> LAP
[4] ATLANTA     Deployed to production (snapshot first!)        -> LAP
```
A change may not advance a stage until the current stage passes THE LAP.
One change moves through the pipeline at a time - never stack untested
changes. Every Atlanta deploy is preceded by a Vultr snapshot.

## THE LAP (certification checklist - run at every stage)
1. **Integrity scan:** run Verify-VerlandContent.ps1 against the stage's
   dat + DB -> ALL GREEN required
2. **Stock-client onboarding** (stages 3-4): rebuild AC-Stock (Assemble
   script) -> login -> DDD patches -> re-run integrity scan on AC-Stock's
   dat -> content must have ARRIVED (guards the hollow-patch bug)
3. **Eyes-on:** login -> visit the content (Mudira shelf etc.) -> renders
   correctly
4. **Stability:** Thwarg-launched session, 5 minutes, no disconnect
5. **Ledger:** record new iteration + portal hash + integrity counts in
   the doctrine's Known-Good block; commit artifacts to repo

## VERSION-SYNC DISCIPLINE
After ANY dat write: run Sync-VerlandDats.ps1 (pushes master client dat
to Local Prod + Local Test, prints iteration + hash). The master copy is
ALWAYS C:\Games\Asheron's Call. Server deploys use the surgery pattern
(ship tool + sources, operate server-side, verify functionally).

## ACE UPDATE PROCEDURE
1. Pull new image on LOCAL first; run it a day
2. Run THE LAP fully on local
3. Friday window: snapshot Atlanta -> re-point pinned digest -> restart
4. Run THE LAP against Atlanta
5. Any failure -> restore snapshot, investigate on local only

## HARD-WON RULES (the trainwreck lessons)
- Client-RENDERED truth is the only truth: byte-perfect data can still
  fail in the 1999 client. The Lap tests rendering, not bytes.
- Custom dat entries need per-entry Iteration stamps or DDD ships
  hollow patches (iteration climbs, cargo absent).
- Icon IDs must stay in the 16-bit window (0x0600xxxx, offset < 0x10000).
- ACE DDD's dat writes are structurally suspect (block-chain defect,
  under investigation) - until resolved, players receive the pre-built
  portal.dat as a download; DDD is belt-and-suspenders only.
- ThwargLauncher's client-path field can silently revert - verify by
  launching, not by reading the field.
- Iteration must match across client and server dats exactly - drift
  causes boots. Sync after every write.
