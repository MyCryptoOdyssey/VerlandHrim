#!/bin/bash
# ============================================================
#  phase3-dats.sh
#  LAYER 3: the custom 2084 portal takes its place server-side.
#  DDD (already ON) will now patch connecting stock clients UP
#  to 2084 - the production onboarding pipeline, live.
#  World data still stock (Phase 4 next). Backup + hash gates.
#
#  RUN ON THE CLEAN BOX:
#    chmod +x /root/phase3-dats.sh && /root/phase3-dats.sh
# ============================================================
set -e
G='\033[1;32m'; C='\033[1;36m'; M='\033[1;35m'; R='\033[1;31m'; N='\033[0m'
step(){ echo -e "\n${C}=== $1 ===${N}"; }
ok(){ echo -e "${G}  [OK] $1${N}"; }
fail(){ echo -e "${R}[FAILED] $1${N}"; exit 1; }

PAY=/root/verland-payload/client_portal.dat
DATDIR=/root/vanilla-ace/Dats
CUSTOM_PREFIX="a8ab63303523"   # your 2084 portal fingerprint

echo -e "${M}PHASE 3 - THE DAT LAYER${N}"

step "1. Verifying the payload portal is the custom 2084"
[ -f "$PAY" ] || fail "Payload portal missing at $PAY"
H=$(md5sum "$PAY" | cut -d' ' -f1)
echo "  payload md5: ${H:0:12}..."
[ "${H:0:12}" = "$CUSTOM_PREFIX" ] || fail "Payload portal hash unexpected - not your custom file"
ok "Custom 2084 portal verified"

step "2. Backing up the server's stock portal"
cp "$DATDIR/client_portal.dat" "$DATDIR/client_portal.dat.stock.bak"
ok "Stock portal preserved: client_portal.dat.stock.bak"

step "3. Installing the custom portal"
cp "$PAY" "$DATDIR/client_portal.dat"
H2=$(md5sum "$DATDIR/client_portal.dat" | cut -d' ' -f1)
[ "${H2:0:12}" = "$CUSTOM_PREFIX" ] || fail "Install verification failed"
ok "Server now carries the 2084 portal"

step "4. Restart + wait"
cd /root/vanilla-ace
docker compose restart ace-server
echo "  Waiting (up to 10 min)..."
OPENED=""
for i in $(seq 1 60); do
  if docker logs --since 3m ace-server 2>/dev/null | grep -q "World is now open"; then OPENED=yes; break; fi
  sleep 10
done
[ -n "$OPENED" ] || { docker logs --tail 15 ace-server | sed 's/^/  /'; fail "World did not open"; }
ok "WORLD OPEN with custom DATs"

echo -e "\n${M}============================================================${N}"
echo -e "${M} PHASE 3 COMPLETE - server carries YOUR 2084 portal${N}"
echo -e ""
echo -e " THE ONBOARDING TEST (gaming PC) - this one is special:"
echo -e "   Same Thwarg setup (Verland_Hrim entry, AC-Stock client,"
echo -e "   Decal ON, Never Kill OFF) -> login cleantest"
echo -e ""
echo -e "   EXPECT: a DAT-PATCHING phase during login - the server"
echo -e "   pushing 2072->2084 to the client. Let it finish completely."
echo -e "   The client may need to restart itself after patching - normal."
echo -e "   Then: character -> world -> FIVE MINUTES."
echo -e ""
echo -e " This login IS your future player's day-one experience."
echo -e " After it passes, AC-Stock carries 2084 (re-stock later with"
echo -e " Assemble-ACStock.ps1 if you ever need a 2072 test client)."
echo -e ""
echo -e " Rollback: cp $DATDIR/client_portal.dat.stock.bak $DATDIR/client_portal.dat && docker compose restart ace-server"
echo -e "${M}============================================================${N}"
