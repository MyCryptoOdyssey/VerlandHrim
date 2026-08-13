#!/bin/bash
# ============================================================
#  restore-both-worlds-v2.sh
#  Same gated sequence, with the CRLF bug fixed:
#  the stock world is filtered to a temp file FIRST, the temp
#  file is PROVEN to contain zero USE/CREATE DATABASE lines,
#  and only then is it poured - into vace_world only.
#
#  RUN:  chmod +x /root/restore-both-worlds-v2.sh
#        /root/restore-both-worlds-v2.sh StarsRangerCowboys2023
# ============================================================
set -e
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1 - STOPPING.${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/restore-both-worlds-v2.sh DBPASSWORD"
Q(){ docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "$1" 2>/dev/null; }

echo -e "${M}RESTORE BOTH WORLDS v2 - CRLF-safe, proof-before-pour${N}"

step "1. Ensuring both game servers are stopped"
systemctl stop ace ace-vanilla 2>/dev/null || true
sleep 3
ok "ace and ace-vanilla stopped"

step "2. Restoring VERLAND from /root/ace_world.sql"
[ -f /root/ace_world.sql ] || fail "/root/ace_world.sql missing"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "DROP DATABASE IF EXISTS ace_world; CREATE DATABASE ace_world;"
echo "  Pouring your 155MB world - several silent minutes..."
docker exec -i ace-db mariadb -uroot -p"$DBPASS" ace_world < /root/ace_world.sql
VC=$(Q "SELECT COUNT(*) FROM ace_world.weenie_properties_string;")
[ "$VC" = "83322" ] || fail "Verland gate: got '$VC', need 83322"
ok "VERLAND VERIFIED: 83322"

step "3. Building CRLF-safe filtered stock world + PROOF"
[ -f /root/vanilla/world.sql ] || fail "/root/vanilla/world.sql missing"
# Strip carriage returns FIRST, then delete USE / CREATE DATABASE lines outright
sed -e 's/\r$//' -e '/^[[:space:]]*CREATE DATABASE/d' -e '/^[[:space:]]*USE[[:space:]]/d' \
    /root/vanilla/world.sql > /root/vanilla/world-safe.sql
BAD=$(grep -cE '^[[:space:]]*(USE[[:space:]]|CREATE DATABASE)' /root/vanilla/world-safe.sql || true)
LINES=$(wc -l < /root/vanilla/world-safe.sql)
TABLES=$(grep -c "CREATE TABLE" /root/vanilla/world-safe.sql || true)
echo "  Filtered file: $LINES lines, $TABLES CREATE TABLE statements, $BAD dangerous lines remaining"
[ "$BAD" = "0" ] || fail "PROOF FAILED: $BAD USE/CREATE DATABASE lines survived filtering - NOT pouring"
[ "$TABLES" -gt 10 ] || fail "Filtered file has only $TABLES CREATE TABLE statements - wrong source file?"
ok "PROOF PASSED: zero dangerous lines, $TABLES tables defined"

step "4. Pouring filtered stock world into vace_world ONLY"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "DROP DATABASE IF EXISTS vace_world; CREATE DATABASE vace_world;"
echo "  Pouring - several minutes..."
docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_world < /root/vanilla/world-safe.sql
ok "Pour complete"

step "5. GATE: both worlds correct"
TW=$(Q "SELECT COUNT(*) FROM vace_world.weenie;" || echo 0)
VC2=$(Q "SELECT COUNT(*) FROM ace_world.weenie_properties_string;" || echo 0)
echo "  Twin weenies: $TW    Verland strings: $VC2"
[ -n "$TW" ] && [ "$TW" -gt 1000 ] || fail "Twin gate: $TW weenies"
[ "$VC2" = "83322" ] || fail "VERLAND CHANGED during twin pour ($VC2) - do not start servers"
ok "BOTH VERIFIED: twin=$TW weenies, Verland=83322"

step "6. Restarting both worlds"
systemctl start ace
systemctl start ace-vanilla
echo "  Waiting up to 3 min for both to open..."
VOPEN=""; TOPEN=""
for i in $(seq 1 36); do
  journalctl -u ace --since "-3 min" --no-pager 2>/dev/null | grep -q "World is now open" && VOPEN=yes
  journalctl -u ace-vanilla --since "-3 min" --no-pager 2>/dev/null | grep -q "World is now open" && TOPEN=yes
  [ -n "$VOPEN" ] && [ -n "$TOPEN" ] && break
  sleep 5
done
[ -n "$VOPEN" ] && ok "VERLAND OPEN (port 9000)" || echo -e "${Y}  Verland not open yet: journalctl -u ace -n 20${N}"
[ -n "$TOPEN" ] && ok "TWIN OPEN (port 9002)"    || echo -e "${Y}  Twin not open yet: journalctl -u ace-vanilla -n 20${N}"

echo -e "\n${M}============================================================${N}"
echo -e "${M} BOTH OPEN? -> THE VERDICT LOGIN:${N}"
echo -e "   Thwarg -> Vanilla-Twin / 45.76.62.139 / port 9002"
echo -e "   BRAND-NEW account -> create character -> TWO-MINUTE CLOCK"
echo -e "${M}============================================================${N}"
