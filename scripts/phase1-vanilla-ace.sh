#!/bin/bash
# ============================================================
#  phase1-vanilla-ace.sh
#  CLEAN ROOM PHASE 1: virgin Ubuntu -> vanilla ACE, strictly
#  by the official ACE Docker guide. No Verland. No deviations
#  except two mandated password changes and the DAT fetch.
#
#  RUN ON THE NEW SERVER (155.138.215.4):
#    chmod +x /root/phase1-vanilla-ace.sh
#    /root/phase1-vanilla-ace.sh 'DBROOTPASS' 'DBUSERPASS'
#  (your two invented vanilla DB passwords, letters+numbers)
# ============================================================
set -e
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
warn(){ echo -e "${Y}  [!!] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

ROOTPW="$1"; USERPW="$2"
[ -n "$ROOTPW" ] && [ -n "$USERPW" ] || fail "Usage: /root/phase1-vanilla-ace.sh 'DBROOTPASS' 'DBUSERPASS'"

echo -e "${M}CLEAN ROOM PHASE 1 - Vanilla ACE by the book${N}"

step "1. System prep (updates, timezone, tools)"
apt-get update -qq && apt-get upgrade -y -qq
timedatectl set-timezone America/Chicago
apt-get install -y -qq curl wget unzip ufw >/dev/null
ok "System current, clock Central"

step "2. Firewall (SSH + game ports)"
ufw allow 22/tcp >/dev/null; ufw allow 9000:9001/udp >/dev/null; ufw --force enable >/dev/null
ok "ufw active: 22/tcp, 9000-9001/udp"

step "3. Docker"
curl -fsSL https://get.docker.com | sh >/dev/null 2>&1
docker --version >/dev/null || fail "Docker install failed"
ok "Docker: $(docker --version | cut -d, -f1)"

step "4. Official guide files (compose + env, straight from the repo)"
mkdir -p /root/vanilla-ace && cd /root/vanilla-ace
wget -q https://raw.githubusercontent.com/ACEmulator/ACE/master/docker-compose.yml
wget -q https://raw.githubusercontent.com/ACEmulator/ACE/master/docker.env
[ -f docker-compose.yml ] && [ -f docker.env ] || fail "Guide file download failed"
# The guide's own two mandated edits: comment build:, change the passwords
sed -i 's/^\(\s*\)build: \./\1# build: ./' docker-compose.yml
sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$ROOTPW|" docker.env
sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$USERPW|" docker.env
sed -i "s|^TZ=.*|TZ=America/Chicago|" docker.env
grep -q "$ROOTPW" docker.env || fail "Password edit did not take"
ok "Official compose + env in place; passwords set; build: commented per guide"

step "5. DAT files (guide's Mega bundle)"
mkdir -p /root/vanilla-ace/Dats
if [ -f /root/ac-updates.zip ]; then
  ok "Found /root/ac-updates.zip (WinSCP'd) - using it"
  unzip -o -j /root/ac-updates.zip "*.dat" -d /root/vanilla-ace/Dats >/dev/null
else
  echo "  Attempting server-side Mega download via megatools..."
  apt-get install -y -qq megatools >/dev/null 2>&1 || true
  if command -v megadl >/dev/null; then
    megadl 'https://mega.nz/#!Q98n0BiR!p5IugPS8ZkQ7uX2A_LdN3Un2_wMX4gZBHowgs1Qomng' \
      --path /root/ac-updates.zip 2>/dev/null || true
  fi
  if [ -f /root/ac-updates.zip ]; then
    unzip -o -j /root/ac-updates.zip "*.dat" -d /root/vanilla-ace/Dats >/dev/null
    ok "Mega download + extract succeeded"
  else
    warn "Mega route failed. FALLBACK: WinSCP your Downloads\\ac-updates (1).zip"
    warn "to /root/ac-updates.zip on this server, then RERUN this script."
    fail "DATs not yet available"
  fi
fi
for d in client_cell_1.dat client_portal.dat client_local_English.dat; do
  [ -f /root/vanilla-ace/Dats/$d ] || fail "Missing $d after extraction"
done
ok "DATs staged: $(ls /root/vanilla-ace/Dats | tr '\n' ' ')"

step "6. LAUNCH - docker compose up (the wizard does the rest)"
cd /root/vanilla-ace
docker compose up -d
ok "Containers starting. First boot: DB init + base schemas + STOCK WORLD"
echo "  DOWNLOAD (the wizard fetches the official world - can take 10+ min)."

step "7. Waiting for 'World is now open' (up to 20 min - the world download is big)"
OPENED=""
for i in $(seq 1 120); do
  if docker logs ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  if docker logs ace-server 2>/dev/null | grep -q "FATAL"; then
    warn "FATAL seen in log - tail follows:"
    docker logs --tail 20 ace-server | sed 's/^/  /'
    fail "Server hit a fatal during first boot"
  fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 20 ace-server | sed 's/^/  /'; fail "World did not open within 20 min - log tail above"; }
ok "VANILLA WORLD IS OPEN"
docker logs ace-server 2>/dev/null | grep -E "Binary|World is now open" | tail -3 | sed 's/^/  /'

echo -e "\n${M}============================================================${N}"
echo -e "${M} PHASE 1 COMPLETE - VANILLA ACE RUNNING BY THE BOOK${N}"
echo -e ""
echo -e " THE VERDICT LOGIN (gaming PC):"
echo -e "   1. Thwarg 'AC Client File Location' -> C:\\Games\\AC-Stock\\acclient.exe"
echo -e "      (STOCK client - matches this server's stock DATs)"
echo -e "   2. New entry: Vanilla-CleanRoom / 155.138.215.4 / port 9000 / ACE"
echo -e "   3. BRAND-NEW account name -> create character -> TWO-MINUTE CLOCK"
echo -e ""
echo -e " SURVIVES -> ACE+Vultr+Thwarg = proven; snapshot 'vanilla-works',"
echo -e "             then layer Verland back stratum by stratum"
echo -e " DIES     -> environment convicted with the purest evidence possible"
echo -e "${M}============================================================${N}"
