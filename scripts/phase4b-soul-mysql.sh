#!/bin/bash
# ============================================================
#  phase4b-soul-mysql.sh
#  FIX + RESUME: translates the dumps' MariaDB-only collations
#  (utf8mb3/utf8mb4 uca1400) into MySQL 8 equivalents, proves
#  none remain, then re-runs the full pour + gates + rebirth.
#
#  RUN ON THE CLEAN BOX:
#    chmod +x /root/phase4b-soul-mysql.sh
#    /root/phase4b-soul-mysql.sh 'VanillaRootPass'
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1 - STOPPING.${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/phase4b-soul-mysql.sh 'DBROOTPASS'"
Q(){ docker exec -i ace-db mysql -uroot -p"$DBPASS" -N -e "$1" 2>/dev/null; }

echo -e "${M}PHASE 4b - COLLATION TRANSLATION + THE SOUL${N}"

step "1. Translating MariaDB collations -> MySQL 8 (all three dumps)"
mkdir -p /root/phase4-mysql
for f in ace_world ace_shard ace_auth; do
  [ -f "/root/phase4-safe/$f.sql" ] || fail "/root/phase4-safe/$f.sql missing - run phase4-soul.sh step 3 first"
  sed -e 's/utf8mb4_uca1400_ai_ci/utf8mb4_0900_ai_ci/g' \
      -e 's/utf8mb3_uca1400_ai_ci/utf8mb3_general_ci/g' \
      -e 's/utf8_uca1400_ai_ci/utf8mb3_general_ci/g' \
      "/root/phase4-safe/$f.sql" > "/root/phase4-mysql/$f.sql"
  LEFT=$(grep -c "uca1400" "/root/phase4-mysql/$f.sql" || true)
  [ "$LEFT" = "0" ] || fail "$f: $LEFT uca1400 references survived translation"
done
ok "PROOF PASSED: zero uca1400 references remain in all three dumps"

step "2. Ensuring game server is stopped"
cd /root/vanilla-ace
docker compose stop ace-server 2>/dev/null || true
ok "ace-server stopped"

step "3. Pouring VERLAND's three databases (world = several minutes)"
docker exec -i ace-db mysql -uroot -p"$DBPASS" -e "
  DROP DATABASE IF EXISTS ace_world; CREATE DATABASE ace_world;
  DROP DATABASE IF EXISTS ace_shard; CREATE DATABASE ace_shard;
  DROP DATABASE IF EXISTS ace_auth;  CREATE DATABASE ace_auth;" 2>/dev/null
echo "  Pouring ace_world..."
docker exec -i ace-db mysql -uroot -p"$DBPASS" ace_world < /root/phase4-mysql/ace_world.sql 2>/dev/null
echo "  Pouring ace_shard..."
docker exec -i ace-db mysql -uroot -p"$DBPASS" ace_shard < /root/phase4-mysql/ace_shard.sql 2>/dev/null
echo "  Pouring ace_auth..."
docker exec -i ace-db mysql -uroot -p"$DBPASS" ace_auth < /root/phase4-mysql/ace_auth.sql 2>/dev/null
ok "All three poured"

step "4. GATES: the soul verified"
VC=$(Q "SELECT COUNT(*) FROM ace_world.weenie_properties_string;")
BC=$(Q "SELECT COUNT(*) FROM ace_shard.biota;")
AC=$(Q "SELECT COUNT(*) FROM ace_auth.account;")
echo "  world strings: $VC (need 83322)   shard biotas: $BC   accounts: $AC"
[ "$VC" = "83322" ] || fail "World gate: got '$VC'"
[ -n "$BC" ] && [ "$BC" -gt 100 ] || fail "Shard gate: got '$BC'"
[ -n "$AC" ] && [ "$AC" -gt 5 ]  || fail "Auth gate: got '$AC'"
ok "VERLAND VERIFIED: 83322 strings, $BC biotas, $AC accounts"

step "5. Rebirth"
docker compose start ace-server
echo "  Waiting for the world (up to 10 min)..."
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
echo -e "   Thwarg client path -> C:\\Games\\Asheron's Call\\acclient.exe (CUSTOM)"
echo -e "   Entry: Verland_Hrim / 155.138.215.4 / 9000"
echo -e "   Decal ON, Never Kill OFF"
echo -e "   boss -> +K A R N -> MARKETPLACE ROLL CALL"
echo -e "   FIVE MINUTES via Thwarg."
echo -e "${M}============================================================${N}"
