#!/bin/bash
source /usr/local/sbin/base

banner
echo " Create Account"
echo ""
read -p $'\033[32m Username: \033[0m' User
# Check If Username Exist, Else Proceed
cat < /etc/passwd | cut -d: -f1 | grep -x -E "^${User}" >/dev/null
if [ $? -eq 0 ]; then
	clear
	banner
	echo ""
	echo "${rd} Username already exists, please try another username${nc}."
	exit 0
else
	read -p $'\033[32m Password: \033[0m' Pass
	read -p $'\033[32m How many days: \033[0m' Days
	echo ""
	echo ""
	clear
	sleep 0.3
	IPADDR=$(wget -4qO- http://ipinfo.io/ip)
	Today=`date +%s`
	Days_Detailed=$(( $Days * 86400 ))
	Expire_On=$(($Today + $Days_Detailed))
	Expiration=$(date -u --date="1970-01-01 $Expire_On sec GMT" +%Y/%m/%d)
	Expiration_Display=$(date -u --date="1970-01-01 $Expire_On sec GMT" '+%d %b %Y')
	opensshport="$(netstat -ntlp | grep -i ssh | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g' )"
	dropbearport="$(netstat -nlpt | grep -i dropbear | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
	ziproxyport="$(netstat -nlpt | grep -i ziproxy | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
	squidport="$(netstat -nlpt | grep -i squid | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
	openvpnport="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2 | xargs | sed 's/ /, /g')"
	useradd -m -s /bin/false $Expiration $User > /dev/null
	cat < /etc/passwd | cut -d: -f1 | grep -x -E "^${User}" &> /dev/null
	echo "$Pass\n$Pass\n" | passwd $User &> /dev/null
	banner
	echo " Your Account Details:"
	echo ""
	echo "${cy} Username: ${nc}"$User
	echo "${cy} Password: ${nc}"$Pass
	echo "${cy} Account Expiry: ${nc}"$Expiration_Display
	echo "${or} Host/IP: ${nc}"$IPADDR
	echo "${or} OpenSSH Port: ${nc}"$opensshport
	echo "${or} Dropbear Port: ${nc}"$dropbearport
	echo "${or} Squid Port: ${nc}"$squidport
	echo "${or} Ziproxy Port: ${nc}"$ziproxyport
	echo "${or} OpenVPN Port: ${nc}"$openvpnport
	echo -e "\n"
	return
fi
