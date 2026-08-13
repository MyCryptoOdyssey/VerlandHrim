#!/bin/bash
# ============================================================
#  fix-vanilla-twin.sh
#  Repairs the twin: rebuilds vace_auth / vace_shard by cloning
#  the SCHEMA (structure only, zero data) from your live,
#  proven ace_auth / ace_shard. Verifies the stock world.
#  Then restarts ace-vanilla and waits for it to open.
#
#  RUN:  chmod +x /root/fix-vanilla-twin.sh
#        /root/fix-vanilla-twin.sh StarsRangerCowboys2023
# ============================================================
set -e
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/fix-vanilla-twin.sh DBPASSWORD"

step "1. Stopping the crashed twin"
systemctl stop ace-vanilla 2>/dev/null || true
ok "ace-vanilla stopped"

step "2. Rebuilding vace_auth + vace_shard from the PROVEN live schemas"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "
  DROP DATABASE IF EXISTS vace_auth;  CREATE DATABASE vace_auth;
  DROP DATABASE IF EXISTS vace_shard; CREATE DATABASE vace_shard;"
# --no-data = structure only; the twin starts with zero accounts/characters
docker exec -i ace-db mariadb-dump -uroot -p"$DBPASS" --no-data --skip-add-drop-table ace_auth  \
  | docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_auth
docker exec -i ace-db mariadb-dump -uroot -p"$DBPASS" --no-data --skip-add-drop-table ace_shard \
  | docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_shard
AT=$(docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='vace_auth';")
ST=$(docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='vace_shard';")
[ "$ST" -gt 5 ] || fail "vace_shard schema clone produced only $ST tables."
ok "Schemas cloned: vace_auth=$AT tables, vace_shard=$ST tables (empty, structure-perfect)"

step "3. Verifying the stock world (vace_world)"
WC=$(docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "SELECT COUNT(*) FROM vace_world.weenie;" 2>/dev/null || echo 0)
if [ "$WC" -gt 1000 ]; then
  ok "Stock world present: $WC weenies"
else
  echo -e "${Y}  vace_world looks empty ($WC) - reloading from /root/vanilla/world.sql${N}"
  [ -f /root/vanilla/world.sql ] || fail "world.sql missing at /root/vanilla - rerun the builder's download step."
  docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "DROP DATABASE IF EXISTS vace_world; CREATE DATABASE vace_world;"
  docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_world < /root/vanilla/world.sql
  WC=$(docker exec -i ace-db mariadb -uroot -p"$DBPASS" -N -e "SELECT COUNT(*) FROM vace_world.weenie;")
  [ "$WC" -gt 1000 ] || fail "World reload still empty ($WC)."
  ok "Stock world loaded: $WC weenies"
fi

step "4. Restarting the twin"
systemctl start ace-vanilla
for i in $(seq 1 36); do
  if journalctl -u ace-vanilla --since "-2 min" --no-pager 2>/dev/null | grep -q "World is now open"; then
    ok "VANILLA TWIN IS OPEN"
    break
  fi
  sleep 5
done
journalctl -u ace-vanilla --since "-3 min" --no-pager | grep -vE "ACE >>" | tail -8 | sed 's/^/  /'

echo -e "\n${M}If 'World is now open' printed above: run the verdict login -${N}"
echo -e "${M}Thwarg entry Vanilla-Twin / 45.76.62.139 / port 9002 / NEW account / character / 2-min clock${N}"
