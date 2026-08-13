#!/bin/bash
# ============================================================
#  phase4c-mariadb-swap.sh
#  THE PROVEN-ENGINE SWAP: mysql:8.0 -> mariadb:12.3 (the
#  combination Verland's dumps were born on), with night-one
#  lessons baked in:
#   - healthcheck mysqladmin -> mariadb-admin
#   - wizard re-init protection (env flags OFF before first boot)
#   - pour BEFORE ace-server ever starts on the new engine
#  Then: gates (83322), rebirth, homecoming instructions.
#
#  RUN ON THE CLEAN BOX:
#    chmod +x /root/phase4c-mariadb-swap.sh
#    /root/phase4c-mariadb-swap.sh 'VanillaRootPass'
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; Y='\033[1;33m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1 - STOPPING.${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/phase4c-mariadb-swap.sh 'DBROOTPASS'"
cd /root/vanilla-ace
QM(){ docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "$1" 2>/dev/null; }

echo -e "${M}PHASE 4c - ENGINE SWAP TO MARIADB + THE SOUL${N}"

step "1. Full stop + removing the MySQL data volume (stock world discarded - by design)"
docker compose down -v
ok "Containers down, volumes cleared"

step "2. Rewriting compose: mariadb:12.3 + healthcheck fix"
cp docker-compose.yml docker-compose.yml.mysql.bak
sed -i 's|image: mysql:8.0|image: mariadb:12.3|' docker-compose.yml
sed -i 's/mysqladmin/mariadb-admin/g' docker-compose.yml
grep -q "mariadb:12.3" docker-compose.yml || fail "Engine edit did not take"
ok "Compose: mariadb:12.3, healthcheck mariadb-admin"

step "3. Wizard re-init protection in docker.env"
cp docker.env docker.env.bak
sed -i 's/^ACE_SQL_INITIALIZE_DATABASES=.*/ACE_SQL_INITIALIZE_DATABASES=false/' docker.env || true
sed -i 's/^ACE_SQL_DOWNLOAD_LATEST_WORLD_RELEASE=.*/ACE_SQL_DOWNLOAD_LATEST_WORLD_RELEASE=false/' docker.env || true
grep -q "ACE_SQL_INITIALIZE_DATABASES=false" docker.env || echo "ACE_SQL_INITIALIZE_DATABASES=false" >> docker.env
grep -q "ACE_SQL_DOWNLOAD_LATEST_WORLD_RELEASE=false" docker.env || echo "ACE_SQL_DOWNLOAD_LATEST_WORLD_RELEASE=false" >> docker.env
ok "Wizard cannot re-initialize or overwrite the world"

step "4. Starting MariaDB alone, waiting for healthy"
docker compose up -d ace-db
for i in $(seq 1 30); do
  ST=$(docker inspect --format '{{.State.Health.Status}}' ace-db 2>/dev/null || echo starting)
  [ "$ST" = "healthy" ] && break
  sleep 5
done
[ "$ST" = "healthy" ] || fail "ace-db never went healthy (status: $ST)"
ok "MariaDB 12.3 healthy"

step "5. Creating databases + pouring Verland (native dialect - no translation)"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "
  CREATE DATABASE IF NOT EXISTS ace_world; CREATE DATABASE IF NOT EXISTS ace_shard; CREATE DATABASE IF NOT EXISTS ace_auth;"
echo "  Pouring ace_world (several minutes)..."
docker exec -i ace-db mariadb -uroot -p"$DBPASS" ace_world < /root/phase4-safe/ace_world.sql
echo "  Pouring ace_shard..."
docker exec -i ace-db mariadb -uroot -p"$DBPASS" ace_shard < /root/phase4-safe/ace_shard.sql
echo "  Pouring ace_auth..."
docker exec -i ace-db mariadb -uroot -p"$DBPASS" ace_auth < /root/phase4-safe/ace_auth.sql
ok "All three poured on native engine"

step "6. GATES"
VC=$(QM "SELECT COUNT(*) FROM ace_world.weenie_properties_string;")
BC=$(QM "SELECT COUNT(*) FROM ace_shard.biota;")
AC=$(QM "SELECT COUNT(*) FROM ace_auth.account;")
echo "  world strings: $VC (need 83322)   shard biotas: $BC   accounts: $AC"
[ "$VC" = "83322" ] || fail "World gate: got '$VC'"
[ -n "$BC" ] && [ "$BC" -gt 100 ] || fail "Shard gate: got '$BC'"
[ -n "$AC" ] && [ "$AC" -gt 5 ]  || fail "Auth gate: got '$AC'"
ok "VERLAND VERIFIED: 83322 strings, $BC biotas, $AC accounts"

step "7. Rebirth on the proven engine"
docker compose up -d ace-server
echo "  Waiting for the world (up to 10 min)..."
OPENED=""
for i in $(seq 1 60); do
  if docker logs --since 3m ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  if docker logs --since 3m ace-server 2>/dev/null | grep -q "FATAL"; then
    docker logs --tail 20 ace-server | sed 's/^/  /'; fail "FATAL during boot - log above"
  fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 20 ace-server | sed 's/^/  /'; fail "World did not open - log above"; }
ok "VERLAND_HRIM IS OPEN"

echo -e "\n${M}============================================================${N}"
echo -e "${M} PHASE 4 COMPLETE - VERLAND_HRIM LIVES (MariaDB, certified base)${N}"
echo -e ""
echo -e " THE HOMECOMING (gaming PC):"
echo -e "   Thwarg client path -> C:\\Games\\Asheron's Call\\acclient.exe (CUSTOM)"
echo -e "   Entry: Verland_Hrim / 155.138.215.4 / 9000"
echo -e "   Decal ON, Never Kill OFF"
echo -e "   boss -> +K A R N -> MARKETPLACE ROLL CALL:"
echo -e "     Asheron buffbot / Lord Portales / Murdira / Town Portal /"
echo -e "     three Society Emissaries"
echo -e "   FIVE MINUTES via Thwarg."
echo -e ""
echo -e " Roll call answers -> Vultr snapshot 'verland-live' -> celebrate."
echo -e "${M}============================================================${N}"
