#!/bin/bash
# ============================================================
#  ops-automation.sh
#  THE SELF-TENDING SERVER BUNDLE (items 2+3+5 + hardening):
#   A. Max 6 game clients per IP
#   B. Self-healing: ace-server restart policy -> unless-stopped
#   C. Security: DB port 3306 -> localhost only
#   D. Version pin: ace image locked to current digest (no
#      surprise updates - upgrades become deliberate acts)
#   E. Nightly 3AM DB backups (keep 7) + backup script
#   F. Friday 2PM maintenance: backup + container restart
#   G. unattended-upgrades (OS security patches)
#  Then restarts the stack and verifies the world opens.
#
#  RUN ON THE CLEAN BOX:
#    chmod +x /root/ops-automation.sh
#    /root/ops-automation.sh 'VanillaRootPass'
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; Y='\033[1;33m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

DBPASS="$1"; [ -n "$DBPASS" ] || fail "Usage: /root/ops-automation.sh 'DBROOTPASS'"
CFG=/root/vanilla-ace/Config/Config.js
CMP=/root/vanilla-ace/docker-compose.yml
cd /root/vanilla-ace

echo -e "${M}OPS AUTOMATION - the server learns to tend itself${N}"

step "A. Max 6 clients per IP"
cp "$CFG" "$CFG.pre-ops.bak"
sed -i -E 's/("MaximumAllowedSessionsPerIPAddress": )-?[0-9]+/\16/' "$CFG"
grep -q '"MaximumAllowedSessionsPerIPAddress": 6' "$CFG" || fail "Session cap edit did not take"
ok "Session cap: 6 per IP"

step "B. Self-healing restart policy"
cp "$CMP" "$CMP.pre-ops.bak"
sed -i 's/restart: on-failure/restart: unless-stopped/' "$CMP"
ok "ace-server: restart unless-stopped (survives crashes AND reboots)"

step "C. Hardening: DB port localhost-only"
sed -i 's|"3306:3306/tcp"|"127.0.0.1:3306:3306/tcp"|' "$CMP"
grep -q '127.0.0.1:3306' "$CMP" && ok "3306 bound to localhost only" || echo -e "${Y}  [!!] 3306 line not found in expected form - check manually later${N}"

step "D. Version pin (no surprise updates)"
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' acemulator/ace:latest 2>/dev/null || true)
if [ -n "$DIGEST" ]; then
  sed -i "s|image: acemulator/ace:latest|image: $DIGEST|" "$CMP"
  ok "Pinned: $DIGEST"
  echo "  (Upgrades are now deliberate: test on local first, then re-point this line.)"
else
  echo -e "${Y}  [!!] Could not resolve digest - image stays on :latest; pin manually later${N}"
fi

step "E. Nightly 3AM backups (keep 7 days)"
mkdir -p /root/backups
cat > /root/backup-verland.sh << EOF
#!/bin/bash
# Nightly Verland DB backup - keeps last 7
STAMP=\$(date +%Y%m%d-%H%M)
DIR=/root/backups/\$STAMP
mkdir -p "\$DIR"
for DB in ace_world ace_shard ace_auth; do
  docker exec ace-db mariadb-dump -uroot -p'$DBPASS' "\$DB" > "\$DIR/\$DB.sql" 2>/dev/null
done
echo "\$(date): backup \$STAMP complete (\$(du -sh \$DIR | cut -f1))" >> /root/backups/backup.log
ls -dt /root/backups/2* | tail -n +8 | xargs rm -rf 2>/dev/null
EOF
chmod +x /root/backup-verland.sh
ok "Backup script: /root/backup-verland.sh"

step "F. Cron: nightly backup + Friday 2PM maintenance"
cat > /root/friday-maintenance.sh << 'EOF'
#!/bin/bash
# Friday 2PM Central: backup, then restart the game server
/root/backup-verland.sh
cd /root/vanilla-ace && docker compose restart ace-server
echo "$(date): Friday maintenance restart complete" >> /root/backups/backup.log
EOF
chmod +x /root/friday-maintenance.sh
( crontab -l 2>/dev/null | grep -v backup-verland | grep -v friday-maintenance ;
  echo "0 3 * * * /root/backup-verland.sh" ;
  echo "0 14 * * 5 /root/friday-maintenance.sh" ) | crontab -
ok "Cron installed: backups 3:00 AM daily, maintenance Friday 2:00 PM (server clock = Central)"

step "G. OS security auto-patching"
apt-get install -y -qq unattended-upgrades >/dev/null 2>&1
dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1 || true
ok "unattended-upgrades active"

step "H. Applying (stack restart) + verification"
docker compose down
docker compose up -d
echo "  Waiting for the world (up to 10 min)..."
OPENED=""
for i in $(seq 1 60); do
  if docker logs --since 3m ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 15 ace-server | sed 's/^/  /'; fail "World did not open after ops changes - log above (rollback: restore .pre-ops.bak files)"; }
ok "WORLD OPEN under new ops config"

step "I. First backup - proving the pipeline"
/root/backup-verland.sh
ls -la /root/backups/ | tail -3 | sed 's/^/  /'
W=$(ls /root/backups/2*/ace_world.sql 2>/dev/null | head -1)
[ -n "$W" ] && [ $(stat -c%s "$W") -gt 100000000 ] || fail "First backup looks wrong - check /root/backups"
ok "Backup pipeline proven ($(du -h "$W" | cut -f1) world dump on disk)"

echo -e "\n${M}============================================================${N}"
echo -e "${M} OPS AUTOMATION COMPLETE - the server tends itself:${N}"
echo -e "   6 clients/IP max | self-healing restarts | localhost DB"
echo -e "   pinned version | 3AM backups x7 | Friday 2PM maintenance"
echo -e "   OS auto-patching"
echo -e ""
echo -e " VERIFY FROM YOUR SIDE: quick Thwarg login (boss) - world's back."
echo -e ""
echo -e " MANUAL ITEMS (5 min, panel/browser):"
echo -e "  1. Vultr snapshot 'verland-live' if not done (freeze this state!)"
echo -e "  2. UptimeRobot.com free account -> Add Monitor -> type: Ping"
echo -e "     -> IP 155.138.215.4 -> alerts to your email. (Game port is"
echo -e "     UDP and can't be probed directly; ping catches box-down.)"
echo -e "${M}============================================================${N}"
