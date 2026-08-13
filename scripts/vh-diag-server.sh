#!/bin/bash
# ============================================================
#  vh-diag-server.sh
#  One-shot server health + evidence report for Verland_Hrim.
#  Safe to run anytime; changes nothing.
#
#  RUN ON THE VULTR SERVER:
#     chmod +x /root/vh-diag-server.sh && /root/vh-diag-server.sh
# ============================================================
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'
hdr(){ echo -e "\n${C}=== $1 ===${N}"; }

echo -e "${M}VERLAND_HRIM SERVER DIAGNOSTIC - $(date)${N}"

hdr "1. ACE service"
systemctl is-active ace >/dev/null && echo -e "${G}  ace service: RUNNING${N}" || echo -e "${R}  ace service: NOT RUNNING${N}"
VER=$(journalctl -u ace --no-pager 2>/dev/null | grep "Current Server Binary" | tail -1 | sed 's/.*Binary: //')
echo "  Binary: ${VER:-unknown}"
journalctl -u ace --no-pager 2>/dev/null | grep -q "World is now open" && echo -e "${G}  World: OPEN (per log history)${N}" || echo -e "${Y}  World open line not found in journal${N}"

hdr "2. Listeners (both game ports must show)"
ss -ulnp | grep -E ":900[01]" | sed 's/^/  /' || echo -e "${R}  NOTHING listening on 9000/9001!${N}"

hdr "3. Firewall"
ufw status | sed 's/^/  /'

hdr "4. NIC offload state (tx-checksum should be OFF)"
ethtool -k enp1s0 2>/dev/null | grep -E "tx-checksum-ip-generic|generic-segmentation|gro" | sed 's/^/  /'

hdr "5. Database"
docker ps --format '  {{.Names}}: {{.Status}}' | grep ace-db || echo -e "${R}  ace-db container not running!${N}"
if [ -n "$1" ]; then
  docker exec -i ace-db mariadb -uroot -p"$1" -e "SELECT table_schema, COUNT(*) tables FROM information_schema.tables WHERE table_schema LIKE 'ace_%' GROUP BY table_schema;" 2>/dev/null | sed 's/^/  /'
  docker exec -i ace-db mariadb -uroot -p"$1" -e "SELECT (SELECT COUNT(*) FROM ace_world.weenie) weenies,(SELECT COUNT(*) FROM ace_shard.biota) biotas,(SELECT COUNT(*) FROM ace_auth.account) accounts;" 2>/dev/null | sed 's/^/  /'
else
  echo -e "${Y}  (pass DB root password as argument for table counts: ./vh-diag-server.sh MyPass)${N}"
fi

hdr "6. Recent connections & drops (last 12 relevant lines)"
journalctl -u ace --no-pager 2>/dev/null | grep -E "connected with verified|dropped|Interrogation" | tail -12 | sed 's/^/  /'

hdr "7. Config quick-view (network + world)"
grep -A6 '"Network"' /opt/ace/Config.js 2>/dev/null | sed 's/^/  /'
grep '"WorldName"' /opt/ace/Config.js 2>/dev/null | sed 's/^/  /'

hdr "8. Config diff vs local (if /root/local-Config.js uploaded)"
if [ -f /root/local-Config.js ]; then
  D=$(diff /root/local-Config.js /opt/ace/Config.js)
  if [ -z "$D" ]; then echo -e "${G}  IDENTICAL${N}"; else echo "$D" | sed 's/^/  /'; fi
else
  echo -e "${Y}  /root/local-Config.js not present - WinSCP your local Config.js there to enable this check${N}"
fi

hdr "9. Live capture helper"
echo "  To watch a login attempt at packet level, run:"
echo "    timeout 120 tcpdump -n -i enp1s0 udp port 9000 or udp port 9001"
echo -e "\n${M}Report complete. Paste output back for analysis.${N}"
