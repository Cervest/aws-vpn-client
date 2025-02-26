#!/bin/bash

set -e
echo "server"
/server &

cp /vpn.{conf,modified.conf}

sed -i '/^auth-user-pass.*$/d' /vpn.modified.conf
sed -i '/^auth-federate.*$/d' /vpn.modified.conf

VPN_HOST=$(cat /vpn.modified.conf | grep 'remote ' | cut -d ' ' -f2)
PORT=$(cat /vpn.modified.conf | grep 'remote ' | cut -d ' ' -f3)
PROTO=$(cat /vpn.modified.conf | grep "proto " | cut -d " " -f2)

echo "Connecting to $VPN_HOST on port $PORT/$PROTO"
wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done
  ((++wait_seconds))
}

# create random hostname prefix for the vpn gw
RAND=$(openssl rand -hex 12)

# resolv manually hostname to IP, as we have to keep persistent ip address
SRV=$(dig a +short "${RAND}.${VPN_HOST}"|head -n1)

# cleanup
rm -f saml-response.txt

echo "Getting SAML redirect URL from the AUTH_FAILED response (host: ${SRV}:${PORT})..."
OVPN_OUT=$(/openvpn --config /vpn.modified.conf --verb 3 \
     --proto "$PROTO" --remote "${SRV}" "${PORT}" \
     --auth-user-pass <( printf "%s\n%s\n" "N/A" "ACS::35001" ) \
    2>&1 | grep AUTH_FAILED,CRV1)
echo $OVPN_OUT

URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')
echo ""
echo ""
echo "Open this URL in your browser and log in (ctrl + click):"
echo $URL
sleep 1
wait_file "saml-response.txt" 30 || {
  echo "SAML Authentication timed out"
  exit 1
}

# get SID from the reply
VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')

echo "Running OpenVPN."

# Finally OpenVPN with a SAML response we got
# Delete saml-response.txt after connect
bash -c "/openvpn --config /vpn.modified.conf \
         --verb 3 --auth-nocache --inactive 3600 \
         --proto $PROTO --remote $SRV $PORT \
         --script-security 2 \
         --route-up '/bin/rm saml-response.txt' \
         --auth-user-pass <( printf \"%s\n%s\n\" \"N/A\" \"CRV1::${VPN_SID}::$(cat saml-response.txt)\" )"
