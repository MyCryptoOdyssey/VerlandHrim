# Verland_Hrim — Operations Doctrine
### The one-page reference · August 2026 · v1.0

---

## THE MACHINE (current state)
- **Production:** Vultr `155.138.215.4` ("verlandhrimace"), Ubuntu 24.04, Atlanta
  - ACE in Docker, image **pinned by digest** (no surprise updates)
  - MariaDB 12.3 in Docker, port 3306 **localhost-only**
  - WorldName: `Verland_Hrim` · DDD DAT patching: **ON** · Max 6 sessions/IP
  - Self-healing: containers restart on crash and on reboot
- **Test:** local Windows machine (ACE v1.77.4778 native, MariaDB 12.3)
  - Prod world at 127.0.0.1:9000 · test world at :9002 as needed
- **Client truth:** custom client `C:\Games\Asheron's Call` (portal 2084);
  stock test client `C:\Games\AC-Stock` (rebuild anytime: Assemble-ACStock.ps1)

## RULE 14 (the two-day lesson - never forget)
**A ThwargLauncher entry's NAME must be byte-identical to the server's
WorldName**, or Thwarg silently kills the client ~1 minute after connect
(server logs "Network Timeout"). 
- All published entries: exactly `Verland_Hrim`
- Never rename the WorldName post-launch
- Testing escape hatch: "Never Kill Clients" checkbox disables the verifier

## CONTENT UPDATE FLOW (the pipeline)
```
1. FIX LOCALLY     - GemForge/SpellForge/SQL on the local test server
2. VERIFY LOCALLY  - play it; confirm the change and no side effects
3. SNAPSHOT        - Vultr snapshot before any prod deploy (30-60 min lead)
4. DEPLOY          - Friday 2 PM window preferred:
     - portal.dat change: WinSCP new portal -> replace
       /root/vanilla-ace/Dats/client_portal.dat -> restart ace-server
       (Phase-3 script pattern; hash-verify before/after)
     - world DB change: dump affected tables locally -> WinSCP ->
       gated pour (CRLF-safe, proof-before-pour, USE-lines stripped,
       server STOPPED during pour) -> verify counts -> restart
5. SPOT-CHECK      - Thwarg login, verify the change live
6. PLAYERS RECEIVE - DDD auto-patches every connecting client. No player
                     action ever required.
```
**Iron rules:** never pour SQL with the game server running · never pour
unfiltered dumps (USE-line poison) · Verland world integrity check is
`SELECT COUNT(*) FROM ace_world.weenie_properties_string;` = **83322**
(update this number when content changes it - and record the new value here)

## ACE VERSION POLICY
- Production runs a **pinned digest**. It never auto-updates.
- Upgrade path: pull new image on LOCAL first -> play a day -> if clean,
  re-point the `image:` line in docker-compose.yml during a Friday window
  -> restart -> spot-check -> snapshot.
- Never run master/latest unpinned in production.

## BACKUP TIERS
1. **Nightly 3 AM** (cron): all 3 DBs -> /root/backups/, keeps 7 days
2. **Vultr auto-backups**: weekly machine images (panel-managed)
3. **Milestone snapshots** (manual, before risky work): current set:
   `pre-cleanroom-aug11` (old box, full history) · `vanilla-works`
   (certified stock base) · `verland-live` (soul + automation)
4. **Local masters**: C:\ace-migration staging + C:\ACE + C:\Games client
   + local DB re-dumpable anytime (stage-verland-hrim.ps1)

## SCHEDULE
- **3:00 AM daily** - automatic DB backup
- **2:00 PM Friday** - automatic maintenance (backup + server restart);
  also the human window for deploys and upgrades
- OS security patches: automatic (unattended-upgrades)

## EMERGENCY PROCEDURES
- **Server acting up:** `docker compose restart ace-server` (in
  /root/vanilla-ace); logs: `docker logs --tail 30 ace-server`
- **World data damaged:** stop ace-server -> pour newest
  /root/backups/*/ace_world.sql via gated pattern -> verify 83322 -> start
- **Box unrecoverable:** deploy new instance from `verland-live` snapshot
  (new IP -> update published entries + Discord announcement)
- **Character wipe (launch decision):** drop+recreate ace_shard & ace_auth
  from base schemas; world untouched
- **Health check one-liner:** `docker ps` (both containers Up/healthy) +
  `docker logs ace-server | grep "World is now open" | tail -1`

## PLAYER-FACING FACTS (for the join post)
- Server name (exact): **Verland_Hrim** · Address: 155.138.215.4 : 9000
- Client: standard end-of-retail files (emulator.ac bundle); server
  auto-patches custom content on first login (DDD)
- Limits: 6 clients per IP · Maintenance: Fridays 2 PM Central
- Launcher: ThwargLauncher supported - entry name MUST be Verland_Hrim
