#!/bin/bash
# ============================================================
#  warm-entry-patch.sh
#  SERVER-SIDE FIX CANDIDATE: makes world entry FAST by
#  pre-warming the vanilla server - world DB precaching ON and
#  every starter town permaloaded - so Thwarg's watchdog has
#  nothing to kill. Player-invisible; no client settings needed.
#
#  RUN ON THE VANILLA BOX:
#    chmod +x /root/warm-entry-patch.sh && /root/warm-entry-patch.sh
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

CFG=/root/vanilla-ace/Config/Config.js
[ -f "$CFG" ] || fail "Config not found at $CFG (is this the vanilla box?)"

echo -e "${M}WARM-ENTRY PATCH - pre-warming world entry${N}"

step "1. Backing up current config"
cp "$CFG" "$CFG.pre-warm.bak"
ok "Backup: $CFG.pre-warm.bak"

step "2. Enabling world database precaching"
sed -i 's/"WorldDatabasePrecaching": false/"WorldDatabasePrecaching": true/' "$CFG"
grep -q '"WorldDatabasePrecaching": true' "$CFG" && ok "Precaching ON" || fail "Precache edit did not take"

step "3. Permaloading ALL starter towns (Holtburg, Shoushi, Yaraq + variants)"
python3 - "$CFG" << 'PYEOF'
import json, re, sys
path = sys.argv[1]
raw = open(path).read()
cfg = json.loads(raw)
starters = [
  {"Id":"0xA9B40000","Description":"Holtburg","Permaload":True,"IncludeAdjacents":True,"Instances":[0]},
  {"Id":"0xC98C0000","Description":"Holtburg South","Permaload":True,"IncludeAdjacents":True,"Instances":[0]},
  {"Id":"0xDA550000","Description":"Shoushi","Permaload":True,"IncludeAdjacents":True,"Instances":[0]},
  {"Id":"0xE63E0000","Description":"Shoushi Southeast","Permaload":True,"IncludeAdjacents":True,"Instances":[0]},
  {"Id":"0x7D640000","Description":"Yaraq","Permaload":True,"IncludeAdjacents":True,"Instances":[0]},
  {"Id":"0x8F580000","Description":"Yaraq North","Permaload":True,"IncludeAdjacents":True,"Instances":[0]},
]
pl = cfg["Server"].setdefault("PreloadedLandblocks", [])
have = {e.get("Id") for e in pl}
added = 0
for s in starters:
    if s["Id"] not in have:
        pl.append(s); added += 1
open(path, "w").write(json.dumps(cfg, indent=2))
print(f"  starter blocks added: {added} (total preloads now {len(pl)})")
PYEOF
ok "Starter towns permaloaded"

step "4. Restarting ace-server with the warm config"
cd /root/vanilla-ace
docker compose restart ace-server
echo "  Waiting for world to open (precaching makes boot SLOWER - up to 10 min)..."
OPENED=""
for i in $(seq 1 60); do
  if docker logs --since 2m ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 15 ace-server | sed 's/^/  /'; fail "World not open after restart - log tail above"; }
ok "WORLD OPEN - warm and ready"
docker logs ace-server 2>/dev/null | grep -iE "precach|preload" | tail -4 | sed 's/^/  /'

echo -e "\n${M}============================================================${N}"
echo -e "${M} THE PLAYER-REALITY TEST (gaming PC):${N}"
echo -e "   Thwarg: Decal injection ON + Never Kill Clients UNCHECKED"
echo -e "           client path C:\\Games\\AC-Stock\\acclient.exe"
echo -e "   Entry:  Vanilla-CleanRoom / 155.138.215.4 / 9000"
echo -e "   Login -> character -> FIVE-MINUTE session"
echo -e ""
echo -e " SURVIVES -> server-side fix FOUND: warm entry beats the watchdog"
echo -e " DIES     -> we read Thwarg's watchdog source and aim again"
echo -e "${M}============================================================${N}"
