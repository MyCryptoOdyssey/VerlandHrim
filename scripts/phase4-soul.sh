#!/bin/bash
# ============================================================
#  phase4-soul.sh
#  LAYER 4 (FINAL): Verland's soul - world, shard, auth -
#  poured over the stock databases, with every gate learned
#  the hard way: server stopped first, CRLF-safe filtering,
#  proof-before-pour, 83322 verification, then rebirth.
#
#  RUN ON THE CLEAN BOX:
#    chmod +x /root/phase4-soul.sh
#    /root/phase4-soul.sh 'VanillaRootPass'
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; Y='\033[1;33m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1 - STOPPING.${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/phase4-soul.sh 'DBROOTPASS'"
PAY=/root/verland-payload
Q(){ docker exec -i ace-db mysql -uroot -p"$DBPASS" -N -e "$1" 2>/dev/null; }

echo -e "${M}PHASE 4 - THE SOUL${N}"

step "1. Payload check"
for f in ace_world.sql ace_shard.sql ace_auth.sql; do
  [ -f "$PAY/$f" ] || fail "$f missing from payload"
done
ok "All three dumps present"

step "2. Stopping the game server (database surgery rule)"
cd /root/vanilla-ace
docker compose stop ace-server
ok "ace-server stopped (ace-db stays up for the pour)"

step "3. CRLF-safe filtering + PROOF for all three dumps"
mkdir -p /root/phase4-safe
for f in ace_world ace_shard ace_auth; do
  sed -e 's/\r$//' -e '/^[[:space:]]*CREATE DATABASE/d' -e '/^[[:space:]]*USE[[:space:]]/d' \
      "$PAY/$f.sql" > "/root/phase4-safe/$f.sql"
  BAD=$(grep -cE '^[[:space:]]*(USE[[:space:]]|CREATE DATABASE)' "/root/phase4-safe/$f.sql" || true)
  [ "$BAD" = "0" ] || fail "$f: $BAD dangerous lines survived filtering"
done
ok "PROOF PASSED: zero USE/CREATE DATABASE lines in all three filtered dumps"

step "4. Pouring VERLAND's three databases (world is the several-minute one)"
docker exec -i ace-db mysql -uroot -p"$DBPASS" -e "
  DROP DATABASE IF EXISTS ace_world; CREATE DATABASE ace_world;
  DROP DATABASE IF EXISTS ace_shard; CREATE DATABASE ace_shard;
  DROP DATABASE IF EXISTS ace_auth;  CREATE DATABASE ace_auth;"
echo "  Pouring ace_world (155MB - several silent minutes)..."
docker exec -i ace-db mysql -uroot -p"$DBPASS" ace_world < /root/phase4-safe/ace_world.sql
echo "  Pouring ace_shard..."
docker exec -i ace-db mysql -uroot -p"$DBPASS" ace_shard < /root/phase4-safe/ace_shard.sql
echo "  Pouring ace_auth..."
docker exec -i ace-db mysql -uroot -p"$DBPASS" ace_auth < /root/phase4-safe/ace_auth.sql
ok "All three poured"

step "5. GATES: the soul verified"
VC=$(Q "SELECT COUNT(*) FROM ace_world.weenie_properties_string;")
BC=$(Q "SELECT COUNT(*) FROM ace_shard.biota;")
AC=$(Q "SELECT COUNT(*) FROM ace_auth.account;")
echo "  world strings: $VC (need 83322)   shard biotas: $BC   accounts: $AC"
[ "$VC" = "83322" ] || fail "World gate: got '$VC'"
[ -n "$BC" ] && [ "$BC" -gt 100 ] || fail "Shard gate: got '$BC'"
[ -n "$AC" ] && [ "$AC" -gt 5 ]  || fail "Auth gate: got '$AC'"
ok "VERLAND VERIFIED: 83322 strings, $BC biotas, $AC accounts"

step "6. Rebirth"
docker compose start ace-server
echo "  Waiting for the world (precache + your data - up to 10 min)..."
OPENED=""
for i in $(seq 1 60); do
  if docker logs --since 3m ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 15 ace-server | sed 's/^/  /'; fail "World did not open - log tail above"; }
ok "VERLAND_HRIM IS OPEN"

echo -e "\n${M}============================================================${N}"
echo -e "${M} PHASE 4 COMPLETE - VERLAND_HRIM LIVES ON CERTIFIED GROUND${N}"
echo -e ""
echo -e " THE HOMECOMING (gaming PC):"
echo -e "   Thwarg client path -> C:\\Games\\Asheron's Call\\acclient.exe"
echo -e "     (YOUR CUSTOM CLIENT now - cleantest is gone with the auth pour)"
echo -e "   Entry: Verland_Hrim / 155.138.215.4 / 9000"
echo -e "   Decal ON, Never Kill OFF"
echo -e "   Login: boss -> +K A R N -> MARKETPLACE ROLL CALL:"
echo -e "     Asheron buffbot / Lord Portales / Murdira / Town Portal /"
echo -e "     three Society Emissaries"
echo -e "   FIVE MINUTES minimum, via Thwarg, watchdog armed."
echo -e ""
echo -e " Roll call answers -> snapshot 'verland-live' and celebrate."
echo -e "${M}============================================================${N}"
