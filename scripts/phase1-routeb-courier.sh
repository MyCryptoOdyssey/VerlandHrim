#!/bin/bash
# ============================================================
#  phase1-routeb-courier.sh
#  ROUTE B: pulls Verland's soul from the snapshot-restored
#  temp box to THIS clean box, server-to-server, with gates.
#  Pulls: 3 SQL dumps, custom portal.dat, Content folder.
#  Touches nothing else; temp box is read-only to us.
#
#  RUN ON THE CLEAN BOX (155.138.215.4):
#    chmod +x /root/phase1-routeb-courier.sh
#    /root/phase1-routeb-courier.sh TEMP_BOX_IP
#  (you will be asked for the temp box's root password twice -
#   it is the OLD Atlanta server password)
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; Y='\033[1;33m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

TEMPIP="$1"; [ -n "$TEMPIP" ] || fail "Usage: /root/phase1-routeb-courier.sh TEMP_BOX_IP"
DEST=/root/verland-payload
mkdir -p "$DEST"

echo -e "${M}ROUTE B COURIER - pulling Verland's soul from $TEMPIP${N}"

step "1. Pulling the three SQL dumps (one password prompt - OLD Atlanta password)"
scp -o StrictHostKeyChecking=accept-new \
    "root@$TEMPIP:/root/ace_auth.sql" \
    "root@$TEMPIP:/root/ace_shard.sql" \
    "root@$TEMPIP:/root/ace_world.sql" \
    "$DEST/"
ok "Dumps pulled"

step "2. Pulling custom portal.dat + Content (second password prompt)"
scp -o StrictHostKeyChecking=accept-new -r \
    "root@$TEMPIP:/root/ACE/Dats/client_portal.dat" \
    "root@$TEMPIP:/root/ACE/Content" \
    "$DEST/"
ok "Portal + Content pulled"

step "3. GATES: size + integrity checks"
w=$(stat -c%s "$DEST/ace_world.sql" 2>/dev/null || echo 0)
p=$(stat -c%s "$DEST/client_portal.dat" 2>/dev/null || echo 0)
s=$(stat -c%s "$DEST/ace_shard.sql" 2>/dev/null || echo 0)
a=$(stat -c%s "$DEST/ace_auth.sql" 2>/dev/null || echo 0)
echo "  ace_world.sql:     $((w/1024/1024)) MB (expect ~155)"
echo "  ace_shard.sql:     $((s/1024)) KB (expect ~547)"
echo "  ace_auth.sql:      $((a/1024)) KB (expect ~9)"
echo "  client_portal.dat: $((p/1024/1024)) MB (expect ~884)"
[ "$w" -gt 150000000 ] || fail "ace_world.sql too small"
[ "$p" -gt 900000000 ] || fail "portal.dat too small"
[ "$s" -gt 400000 ]    || fail "ace_shard.sql too small"
[ "$a" -gt 4000 ]      || fail "ace_auth.sql too small"
CT=$(find "$DEST/Content" -type f 2>/dev/null | wc -l)
echo "  Content files:     $CT"
# Portal must be the CUSTOM one (differs from the stock the server runs)
STOCKMD5=$(md5sum /root/vanilla-ace/Dats/client_portal.dat | cut -d' ' -f1)
PAYMD5=$(md5sum "$DEST/client_portal.dat" | cut -d' ' -f1)
echo "  payload portal md5: ${PAYMD5:0:12}...  (server's stock: ${STOCKMD5:0:12}...)"
[ "$PAYMD5" != "$STOCKMD5" ] || fail "Payload portal is STOCK, not your custom 2084 - wrong file pulled"
ok "ALL GATES PASSED - Verland's soul is aboard the clean box"

echo -e "\n${M}============================================================${N}"
echo -e "${M} PAYLOAD SECURED at $DEST${N}"
echo -e ""
echo -e "${Y} >>> NOW DESTROY THE TEMP BOX (Vultr panel -> temp-donor ->${N}"
echo -e "${Y} >>> trash can -> confirm). It bills hourly until you do. <<<${N}"
echo -e ""
echo -e " Next: Phase 2 (WorldName + DDD config layer + Thwarg test)."
echo -e "${M}============================================================${N}"
