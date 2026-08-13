#!/bin/bash
# ============================================================
#  restore-both-worlds.sh
#  ONE SAFE SEQUENCE, VERIFIED AT EVERY GATE:
#   1. Stop both servers (no live connections during surgery)
#   2. Restore Verland's ace_world from /root/ace_world.sql
#   3. GATE: verify 83322
#   4. Pour stock world into vace_world ONLY (USE lines stripped)
#   5. GATE: verify twin populated AND Verland still 83322
#   6. Restart both; wait for both "World is now open"
#
#  RUN:  chmod +x /root/restore-both-worlds.sh
#        /root/restore-both-worlds.sh StarsRangerCowboys2023
# ============================================================
set -e
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1 - STOPPING. Nothing further will run.${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/restore-both-worlds.sh DBPASSWORD"
Q(){ docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "$1" 2>/dev/null; }

echo -e "${M}RESTORE BOTH WORLDS - full sequence with verification gates${N}"

step "1. Stopping both game servers (database surgery requires it)"
systemctl stop ace 2>/dev/null || true
systemctl stop ace-vanilla 2>/dev/null || true
sleep 3
ok "ace and ace-vanilla stopped"

step "2. Restoring VERLAND's world from /root/ace_world.sql"
[ -f /root/ace_world.sql ] || fail "/root/ace_world.sql missing - the migration dump is the recovery source"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "DROP DATABASE IF EXISTS ace_world; CREATE DATABASE ace_world;"
echo "  Pouring 155MB - several silent minutes, let it grind..."
docker exec -i ace-db mariadb -uroot -p"$DBPASS" ace_world < /root/ace_world.sql
ok "Pour complete"

step "3. GATE: Verland integrity"
VC=$(Q "SELECT COUNT(*) FROM ace_world.weenie_properties_string;")
[ "$VC" = "83322" ] || fail "Verland check returned '$VC' (need 83322)"
ok "VERLAND VERIFIED: 83322"

step "4. Pouring STOCK world into the twin (vace_world) - USE lines stripped"
[ -f /root/vanilla/world.sql ] || fail "/root/vanilla/world.sql missing"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "DROP DATABASE IF EXISTS vace_world; CREATE DATABASE vace_world;"
echo "  Pouring stock 149MB into vace_world ONLY - several minutes..."
sed -E 's/^(CREATE DATABASE|USE )[^;]*;?$//' /root/vanilla/world.sql \
  | docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_world
ok "Stock pour complete"

step "5. GATE: both worlds correct"
TW=$(Q "SELECT COUNT(*) FROM vace_world.weenie;")
VC2=$(Q "SELECT COUNT(*) FROM ace_world.weenie_properties_string;")
echo "  Twin weenies: $TW    Verland strings: $VC2"
[ -n "$TW" ] && [ "$TW" -gt 1000 ] || fail "Twin world looks wrong ($TW weenies)"
[ "$VC2" = "83322" ] || fail "VERLAND CHANGED during twin pour ($VC2) - the strip failed; do not start servers"
ok "BOTH WORLDS VERIFIED: twin=$TW weenies, Verland=83322 intact"

step "6. Restarting both servers"
systemctl start ace
systemctl start ace-vanilla
echo "  Waiting up to 3 min for both worlds to open..."
VOPEN=""; TOPEN=""
for i in $(seq 1 36); do
  journalctl -u ace --since "-3 min" --no-pager 2>/dev/null | grep -q "World is now open" && VOPEN=yes
  journalctl -u ace-vanilla --since "-3 min" --no-pager 2>/dev/null | grep -q "World is now open" && TOPEN=yes
  [ -n "$VOPEN" ] && [ -n "$TOPEN" ] && break
  sleep 5
done
[ -n "$VOPEN" ] && ok "VERLAND: World is now open (port 9000)" || echo -e "${Y}  Verland open-line not seen yet - check: journalctl -u ace -n 20${N}"
[ -n "$TOPEN" ] && ok "TWIN: World is now open (port 9002)"    || echo -e "${Y}  Twin open-line not seen yet - check: journalctl -u ace-vanilla -n 20${N}"

echo -e "\n${M}============================================================${N}"
echo -e "${M} IF BOTH SHOW OPEN: run the verdict login -${N}"
echo -e "   Thwarg -> Vanilla-Twin / 45.76.62.139 / port 9002"
echo -e "   BRAND-NEW account name -> create character -> TWO-MINUTE CLOCK"
echo -e "${M}============================================================${N}"
