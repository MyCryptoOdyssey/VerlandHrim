#!/bin/bash
# ============================================================
#  install-ace-stable.sh
#  Replaces the Docker master-build ace-server with the official
#  STABLE release (v1.77.4778) running natively under systemd.
#  The MariaDB container (ace-db) stays exactly as it is.
#
#  RUN ON THE VULTR SERVER:
#     chmod +x /root/install-ace-stable.sh
#     /root/install-ace-stable.sh
# ============================================================

set -e  # stop on any error

step()  { echo -e "\n\033[1;36m=== $1 ===\033[0m"; }
ok()    { echo -e "\033[1;32m  [OK] $1\033[0m"; }
warn()  { echo -e "\033[1;33m  [!!] $1\033[0m"; }
fail()  { echo -e "\033[1;31m[FAILED] $1\033[0m"; exit 1; }

step "1. Stopping and removing the Docker ace-server (master build)"
cd /root/ACE
docker compose stop ace-server 2>/dev/null || true
docker compose rm -f ace-server 2>/dev/null || true
ok "Docker ace-server retired. (ace-db database container untouched.)"

step "2. Installing .NET 8 runtime"
apt-get update -qq
apt-get install -y -qq dotnet-runtime-8.0 unzip >/dev/null
dotnet --list-runtimes | grep -q "Microsoft.NETCore.App 8" || warn ".NET 8 runtime not detected - ACE may need a different runtime; watch the first start."
ok ".NET runtime ready: $(dotnet --version 2>/dev/null || echo 'runtime-only install')"

step "3. Downloading official ACE release v1.77.4778 from GitHub"
API_JSON=$(curl -s "https://api.github.com/repos/ACEmulator/ACE/releases/latest")
TAG=$(echo "$API_JSON" | grep -m1 '"tag_name"' | cut -d'"' -f4)
URL=$(echo "$API_JSON" | grep '"browser_download_url"' | grep -i '\.zip' | head -1 | cut -d'"' -f4)
[ -n "$URL" ] || fail "Could not find a release zip URL (GitHub API said tag: '$TAG'). Check https://github.com/ACEmulator/ACE/releases manually."
echo "  Release tag: $TAG"
echo "  Asset:       $URL"
echo "$TAG" | grep -q "4778" || warn "Latest release is $TAG, not 4778 - should still be a stable release build, proceeding."
mkdir -p /opt/ace-download
curl -sL "$URL" -o /opt/ace-download/ace-release.zip
ok "Downloaded $(du -h /opt/ace-download/ace-release.zip | cut -f1)"

step "4. Installing binaries to /opt/ace"
rm -rf /opt/ace-extract /opt/ace
mkdir -p /opt/ace-extract
unzip -q /opt/ace-download/ace-release.zip -d /opt/ace-extract
# Find the folder that actually contains ACE.Server.dll (zip layouts vary)
BINDIR=$(dirname "$(find /opt/ace-extract -name 'ACE.Server.dll' | head -1)")
[ -n "$BINDIR" ] || fail "ACE.Server.dll not found inside the release zip."
mkdir -p /opt/ace
cp -r "$BINDIR"/. /opt/ace/
ok "Binaries installed. Version check:"
strings /opt/ace/ACE.Server.dll 2>/dev/null | grep -m1 "1\.77\." || true

step "5. Wiring up your existing Config, Dats, Content, Logs, Mods"
# Config.js references container paths like /ace/Dats - recreate them as symlinks
mkdir -p /ace
for d in Dats Content Logs Mods Config; do
  mkdir -p "/root/ACE/$d"
  rm -rf "/ace/$d"
  ln -s "/root/ACE/$d" "/ace/$d"
done
# ACE.Server reads Config.js from its own folder
cp /root/ACE/Config/Config.js /opt/ace/Config.js
grep -q '"Host": "127.0.0.1"' /opt/ace/Config.js && ok "Config.js present, DB host = 127.0.0.1" || warn "Config.js DB host is not 127.0.0.1 - check it."
ok "Paths wired: /ace/* -> /root/ACE/*"

step "6. Creating systemd service (auto-start, auto-restart)"
cat > /etc/systemd/system/ace.service << 'EOF'
[Unit]
Description=ACEmulator Server (Verland_Hrim) - stable release build
After=network-online.target docker.service
Wants=network-online.target

[Service]
WorkingDirectory=/opt/ace
ExecStart=/usr/bin/dotnet /opt/ace/ACE.Server.dll
Restart=always
RestartSec=10
StandardInput=null
# Give the MariaDB container time to come up after a reboot
ExecStartPre=/bin/sleep 20

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ace >/dev/null 2>&1
ok "Service 'ace' created and enabled on boot."

step "7. Starting the stable server"
systemctl start ace
sleep 25
echo "  --- last 15 log lines ---"
journalctl -u ace -n 15 --no-pager | sed 's/^/  /'

echo ""
echo -e "\033[1;35m============================================================\033[0m"
echo -e "\033[1;35m Done. Useful commands from here on:\033[0m"
echo -e "   journalctl -u ace -f          # watch the live server log (Ctrl+C to stop watching)"
echo -e "   systemctl restart ace         # bounce the world"
echo -e "   systemctl status ace          # is it running?"
echo -e "\033[1;35m Watch the log for 'World is now open', then LOGIN TEST.\033[0m"
echo -e "\033[1;35m Note: no ACE >> console under systemd - use in-game @commands\033[0m"
echo -e "\033[1;35m (your admin account status migrated with ace_auth).\033[0m"
echo -e "\033[1;35m============================================================\033[0m"
