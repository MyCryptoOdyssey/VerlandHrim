#!/bin/bash
# ============================================================
#  build-vanilla-twin.sh
#  THE DIFFERENTIAL EXPERIMENT: builds a completely STOCK ACE
#  world ("vanilla twin") on ports 9002/9003, beside Verland.
#  Same box, same OS, same network - ONLY the data/config differ.
#  Verland_Hrim is not touched in any way.
#
#  RUN ON THE VULTR SERVER:
#     chmod +x /root/build-vanilla-twin.sh
#     /root/build-vanilla-twin.sh YOUR_DB_ROOT_PASSWORD
# ============================================================
set -e
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

DBPASS="$1"
[ -n "$DBPASS" ] || fail "Usage: /root/build-vanilla-twin.sh YOUR_DB_ROOT_PASSWORD  (the Atlanta DB root password)"

echo -e "${M}VANILLA TWIN BUILDER - stock ACE world on ports 9002/9003${N}"

step "1. Sanity: Verland must stay healthy"
systemctl is-active ace >/dev/null || fail "Main 'ace' service not running - fix that first."
docker exec ace-db mariadb -uroot -p"$DBPASS" -e "SELECT 1;" >/dev/null 2>&1 || fail "DB password rejected."
ok "Verland service up; DB password verified"

step "2. Copying server binaries to /opt/ace-vanilla"
rm -rf /opt/ace-vanilla
cp -r /opt/ace /opt/ace-vanilla
rm -f /opt/ace-vanilla/Config.js
ok "Binary copy made (config removed - twin gets its own)"

step "3. Stock DATs for the twin"
mkdir -p /root/vanilla/Dats /root/vanilla/Content /root/vanilla/Logs /root/vanilla/Mods
# Try the ACE releases for a DAT bundle; if unavailable, fall back to reusing
# the existing DATs (server-side DAT use is for world geometry; the
# client-compat variable being tested is config/world data, and the twin's
# DDD will see whatever iteration these carry).
if [ ! -f /root/vanilla/Dats/client_portal.dat ]; then
  echo -e "${Y}  No separate stock DAT bundle staged at /root/vanilla/Dats.${N}"
  echo -e "${Y}  Using the existing server DATs for the twin (world geometry only).${N}"
  cp /root/ACE/Dats/client_cell_1.dat /root/vanilla/Dats/
  cp /root/ACE/Dats/client_portal.dat /root/vanilla/Dats/
  cp /root/ACE/Dats/client_highres.dat /root/vanilla/Dats/ 2>/dev/null || true
  cp /root/ACE/Dats/client_local_English.dat /root/vanilla/Dats/
  ok "DATs staged (NOTE: shared with Verland - see experiment notes at end)"
fi

step "4. Creating vanilla databases (vace_auth / vace_shard / vace_world)"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" -e "
  DROP DATABASE IF EXISTS vace_auth; DROP DATABASE IF EXISTS vace_shard; DROP DATABASE IF EXISTS vace_world;
  CREATE DATABASE vace_auth;  CREATE DATABASE vace_shard;  CREATE DATABASE vace_world;"
ok "Empty vanilla databases created"

step "5. Loading base schemas from the ACE repo copy"
BASE=/root/ACE/Database/Base
[ -f "$BASE/AuthenticationBase.sql" ] || fail "Base SQL not found at $BASE"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_auth  < "$BASE/AuthenticationBase.sql"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_shard < "$BASE/ShardBase.sql"
ok "Auth + Shard base loaded"
# Apply shard/auth update scripts in order (same ones the wizard applies)
for f in $(ls /root/ACE/Database/Updates/Shard/*.sql 2>/dev/null | sort); do
  docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_shard < "$f" || true
done
for f in $(ls /root/ACE/Database/Updates/Authentication/*.sql 2>/dev/null | sort); do
  docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_auth < "$f" || true
done
ok "Update scripts applied"

step "6. Downloading the OFFICIAL STOCK world database (the big download)"
cd /root/vanilla
if [ ! -f world.sql ]; then
  WURL=$(curl -s https://api.github.com/repos/ACEmulator/ACE-World-16PY-Patches/releases/latest \
        | grep browser_download_url | grep -iE '\.sql|\.zip|\.gz' | head -1 | cut -d'"' -f4)
  [ -n "$WURL" ] || fail "Could not resolve stock world release URL from GitHub."
  echo "  Fetching: $WURL"
  curl -sL "$WURL" -o world-release
  case "$WURL" in
    *.zip) apt-get install -y -qq unzip >/dev/null; unzip -o world-release >/dev/null; ;;
    *.gz)  mv world-release world.sql.gz; gunzip -f world.sql.gz; ;;
    *.sql) mv world-release world.sql; ;;
  esac
  # Find the resulting sql
  SQLF=$(ls *.sql 2>/dev/null | head -1)
  [ -n "$SQLF" ] || fail "World release downloaded but no .sql found after extraction."
  [ "$SQLF" = "world.sql" ] || mv "$SQLF" world.sql
fi
ok "Stock world SQL ready: $(du -h /root/vanilla/world.sql | cut -f1)"

step "7. Loading stock world into vace_world (several minutes - let it grind)"
docker exec -i ace-db mariadb -uroot -p"$DBPASS" vace_world < /root/vanilla/world.sql
ok "Stock world loaded"

step "8. Writing the twin's Config.js (wizard defaults, ports 9002)"
cat > /opt/ace-vanilla/Config.js << EOF
{
  "Server": {
    "WorldName": "Vanilla_Twin",
    "Network": {
      "Host": "0.0.0.0",
      "Port": 9002,
      "MaximumAllowedSessions": 128,
      "DefaultSessionTimeout": 60,
      "MaximumAllowedSessionsPerIPAddress": -1,
      "AllowUnlimitedSessionsFromIPAddresses": []
    },
    "Accounts": {
      "OverrideCharacterPermissions": false,
      "DefaultAccessLevel": 0,
      "AllowAutoAccountCreation": true,
      "PasswordHashWorkFactor": 8
    },
    "DatFilesDirectory": "/root/vanilla/Dats/",
    "WorldDatabasePrecaching": false,
    "LandblockPreloading": true,
    "PreloadedLandblocks": [
      { "Id": "0xE74EFFFF", "Description": "Hebian-To (Global Events)", "Permaload": true,
        "IncludeAdjacents": true, "Instances": [ 0 ] }
    ],
    "ShutdownInterval": 60,
    "DDD": { "EnableDATPatching": false }
  },
  "MySql": {
    "Authentication": { "Host": "127.0.0.1", "Port": 3306, "Database": "vace_auth",
      "Username": "root", "Password": "$DBPASS" },
    "Shard": { "Host": "127.0.0.1", "Port": 3306, "Database": "vace_shard",
      "Username": "root", "Password": "$DBPASS" },
    "World": { "Host": "127.0.0.1", "Port": 3306, "Database": "vace_world",
      "Username": "root", "Password": "$DBPASS" }
  }
}
EOF
ok "Config written: Vanilla_Twin on port 9002, defaults everywhere"

step "9. Firewall + systemd service"
ufw allow 9002:9003/udp >/dev/null
cat > /etc/systemd/system/ace-vanilla.service << 'EOF'
[Unit]
Description=ACE Vanilla Twin (experiment) - stock world on 9002
After=network-online.target docker.service

[Service]
WorkingDirectory=/opt/ace-vanilla
ExecStart=/usr/bin/dotnet /opt/ace-vanilla/ACE.Server.dll
Restart=always
RestartSec=10
StandardInput=null
Environment=ACE_NONINTERACTIVE_CONSOLE=true
ExecStartPre=/bin/sleep 5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ace-vanilla >/dev/null 2>&1
systemctl start ace-vanilla
ok "ace-vanilla service started (ports 9002/9003 open)"

step "10. Waiting for the twin's world to open (up to 3 min)"
for i in $(seq 1 36); do
  if journalctl -u ace-vanilla --no-pager 2>/dev/null | grep -q "World is now open"; then
    ok "VANILLA TWIN IS OPEN"
    break
  fi
  sleep 5
done
journalctl -u ace-vanilla --no-pager | grep -vE "ACE >>" | tail -8 | sed 's/^/  /'

echo -e "\n${M}============================================================${N}"
echo -e "${M} THE EXPERIMENT (on your gaming PC):${N}"
echo -e "  1. ThwargLauncher -> add entry:  Vanilla-Twin  45.76.62.139  port 9002  (ACE)"
echo -e "  2. Log in with ANY brand-new account name (auto-create is on)"
echo -e "  3. Create a character -> TWO-MINUTE CLOCK"
echo -e ""
echo -e "  TWIN SURVIVES  -> your data/config is the trigger (bisect Verland's changes)"
echo -e "  TWIN DIES TOO  -> environment convicted; dossier ships gold-plated"
echo -e ""
echo -e "${M} Useful:${N}"
echo -e "  journalctl -u ace-vanilla -f            # watch twin log"
echo -e "  systemctl stop ace-vanilla              # pause the twin"
echo -e "${M} TEARDOWN when done:${N}"
echo -e "  systemctl disable --now ace-vanilla; rm -rf /opt/ace-vanilla /root/vanilla /etc/systemd/system/ace-vanilla.service; systemctl daemon-reload; ufw delete allow 9002:9003/udp"
echo -e "${M}============================================================${N}"
