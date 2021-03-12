#!/bin/bash
source /usr/local/sbin/base

opensshport="$(netstat -ntlp | grep -i ssh | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
dropbearport="$(netstat -nlpt | grep -i dropbear | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
squidport="$(netstat -nlpt | grep -i squid | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
ziproxyport="$(netstat -nlpt | grep -i ziproxy | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
openvpnport="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
badvpnport="$(netstat -nlpt | grep -i badvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"


banner
echo " Service Ports"
echo ""
echo " ${cy}OpenSSH Port${nc}: "$opensshport
echo " ${cy}Dropbear Port${nc}: "$dropbearport
echo " ${cy}Squid Port${nc}: "$squidport
echo " ${cy}Ziproxy Port${nc}: "$ziproxyport
echo " ${cy}OpenVPN Port${nc}: "$openvpnport
echo " ${cy}Badvpn-udpgw Port${nc}: "$badvpnport
echo -e "\n"
return