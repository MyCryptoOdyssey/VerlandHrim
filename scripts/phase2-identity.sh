#!/bin/bash
# ============================================================
#  phase2-identity.sh
#  LAYER 2: the server takes its true name.
#   - WorldName: ACEmulator -> Verland_Hrim
#   - DDD DAT patching: ON (player onboarding)
#  World data stays STOCK (that's Phase 4). Backup + gates.
#
#  RUN ON THE CLEAN BOX:
#    chmod +x /root/phase2-identity.sh && /root/phase2-identity.sh
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

CFG=/root/vanilla-ace/Config/Config.js
[ -f "$CFG" ] || fail "Config not found at $CFG"

echo -e "${M}PHASE 2 - THE IDENTITY LAYER${N}"

step "1. Backup"
cp "$CFG" "$CFG.pre-phase2.bak"
ok "Backup: $CFG.pre-phase2.bak"

step "2. WorldName -> Verland_Hrim"
sed -i 's/"WorldName": "ACEmulator"/"WorldName": "Verland_Hrim"/' "$CFG"
grep -q '"WorldName": "Verland_Hrim"' "$CFG" || fail "WorldName edit did not take"
ok "WorldName: Verland_Hrim (byte-exact, underscore included)"

step "3. DDD DAT patching -> ON"
sed -i 's/"EnableDATPatching": false/"EnableDATPatching": true/' "$CFG"
grep -q '"EnableDATPatching": true' "$CFG" || fail "DDD edit did not take"
ok "DDD patching enabled"

step "4. Restart + wait for world"
cd /root/vanilla-ace
docker compose restart ace-server
echo "  Waiting (precaching makes boot slower - up to 10 min)..."
OPENED=""
for i in $(seq 1 60); do
  if docker logs --since 3m ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 15 ace-server | sed 's/^/  /'; fail "World did not open - log tail above"; }
ok "WORLD OPEN under its new name"
docker logs ace-server 2>/dev/null | grep -iE "DDD|Patching|DDDManager" | tail -2 | sed 's/^/  /'

echo -e "\n${M}============================================================${N}"
echo -e "${M} PHASE 2 COMPLETE - the server now answers as Verland_Hrim${N}"
echo -e ""
echo -e " THE NAME-LAYER TEST (gaming PC):"
echo -e "   Thwarg: entry named EXACTLY Verland_Hrim / 155.138.215.4 / 9000"
echo -e "           client path C:\\Games\\AC-Stock\\acclient.exe"
echo -e "           Decal ON, Never Kill OFF"
echo -e "   Login (cleantest works) -> character -> FIVE MINUTES"
echo -e ""
echo -e " NOTE: world is still STOCK (Holtburg, not your content) - correct!"
echo -e " NOTE: with DDD on, this login will PATCH AC-Stock's portal to"
echo -e "       whatever the server's Dats carry (still stock now, so no-op;"
echo -e "       after Phase 3 it will patch clients UP to 2084 - by design)."
echo -e ""
echo -e " Old ACEmulator entry: now dead (name mismatch) - delete after test."
echo -e " Rollback if ever needed: cp $CFG.pre-phase2.bak $CFG && docker compose restart ace-server"
echo -e "${M}============================================================${N}"
