#!/bin/bash
# Compiled Installer for Vmess, Vless and Shdowsocks with v2ray plugin

# Get Credentials
get_creds (){
	clear
	echo -e "\n"
	#read -p "$(echo -e '\033[1;36mCertificate: \033[1;34m')" CERT
	#read -p "$(echo -e '\033[1;36mKey: \033[1;34m')" KEY
	read -p "$(echo -e '\033[1;36mDomain: \033[1;34m')" DOM
	echo -e "\033[0m"
	str=`echo $DOM | grep '^\([a-zA-Z0-9_\-]\{1,\}\.\)\{1,\}[a-zA-Z]\{2,5\}'`
	while [ ! -n "${str}" ]
	do
	echo "\033[1;31mInvalid domain, please try again\033[0m"
		read -p "$(echo -e '\033[1;36mDomain: \033[1;34m')" DOM
	str=`echo $DOM | grep '^\([a-zA-Z0-9_\-]\{1,\}\.\)\{1,\}[a-zA-Z]\{2,5\}'`
	done
}

# Install v2ray and nginx-full
install_v2ray (){
	[[ ! -f /usr/local/bin/v2ctl ]] && bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
	[[ ! -f /etc/nginx/nginx.conf ]] && apt install nginx-full -y
}

# Get Cert & Key
cert_key (){
	if [[ ! -f /usr/local/etc/v2ray/fullchain.pem ]]; then
		mkdir /usr/local/etc/v2ray/
		#wget --no-check-certificate -O /usr/local/etc/v2ray/cert.pem "$CERT"
		#wget --no-check-certificate -O /usr/local/etc/v2ray/key.pem "$KEY"
		wget --no-check-certificate -O /usr/local/etc/v2ray/cert.pem "https://www.dropbox.com/s/lzzmafwolc6zh2r/phclngsakalam-cert.pem?dl=0"
		wget --no-check-certificate -O /usr/local/etc/v2ray/key.pem "https://www.dropbox.com/s/7jsc6tnwl247itq/phclngsakalam-key.pem?dl=0"		
		curl -kL "https://support.cloudflare.com/hc/article_attachments/360037898732/origin_ca_ecc_root.pem" -o /usr/local/etc/v2ray/root_ecc.pem
		v2raydir='/usr/local/etc/v2ray' && printf "%b\n" "$(cat $v2raydir/cert.pem)\n$(cat $v2raydir/cert.pem)\n$(cat $v2raydir/root_ecc.pem)" > $v2raydir/fullchain.pem
	else
		:
	fi
}

# Configure Vmess
vmess_conf () {
	UUID=$(v2ctl uuid)
	v2rayconf='/usr/local/etc/v2ray/vmess.json' && nginxv2conf='/etc/nginx/conf.d/v2ray.conf' && gistlink='https://gist.github.com/Earthing007/a540470d6042680fbf88fdaa1a8e0e78/raw' && curl -kL "$gistlink/vmess.json" -o $v2rayconf && curl -kL "$gistlink/v2ray.conf" -o $nginxv2conf && sed -i "s|SERVER_DOMAIN|$DOM|g;s|GENERATED_UUID_CODE|$UUID|g" $v2rayconf && sed -i "s|DOMAIN_HERE|$DOM|g" $nginxv2conf
	rm -rf /etc/nginx/{default.d,conf.d/default.conf,sites-*}
	rm -f /usr/local/etc/v2ray/config.json && cp /usr/local/etc/v2ray/vmess.json /usr/local/etc/v2ray/config.json && rm -f /usr/local/etc/v2ray/vless.json
}

# Configure Vless
vless_conf (){
	UUID=$(v2ctl uuid)
	v2rayconf='/usr/local/etc/v2ray/vless.json' && nginxv2conf='/etc/nginx/conf.d/v2ray.conf' && gistlink='https://gist.github.com/Earthing007/a540470d6042680fbf88fdaa1a8e0e78/raw' && curl -kL "$gistlink/vless.json" -o $v2rayconf && curl -kL "$gistlink/v2ray.conf" -o $nginxv2conf && sed -i "s|SERVER_DOMAIN|$DOM|g;s|GENERATED_UUID_CODE|$UUID|g" $v2rayconf && sed -i "s|DOMAIN_HERE|$DOM|g" $nginxv2conf
	rm -rf /etc/nginx/{default.d,conf.d/default.conf,sites-*}
	rm -f /usr/local/etc/v2ray/config.json && cp /usr/local/etc/v2ray/vless.json /usr/local/etc/v2ray/config.json && rm -f /usr/local/etc/v2ray/vmess.json
	rm -f vless_client.json
	vless_client='https://gist.githubusercontent.com/Earthing007/bfd609dc57e0760bc7e620752c34116c/raw/vless_client.json' && curl -kL "$vless_client" -o vless_client_GTM.json && sed -i "s|SERVER_DOMAIN|$DOM|g;s|GENERATED_UUID_CODE|$UUID|g" vless_client_GTM.json
	for JSON in "vless_client_STS.json" "vless_client_GOMO.json"; do cp vless_client_GTM.json $JSON; done
	sed -i "s|104.17.64.3|45.60.158.66|g" vless_client_STS.json
	sed -i "s|104.17.64.3|104.18.1.27|g" vless_client_GOMO.json
	DATE=$(date --rfc-3339=date)
	LOC=$(curl -sk ipinfo.io/region)
	zip vless_${LOC}_${DATE}.zip vless_client_GOMO.json vless_client_STS.json vless_client_GTM.json
}

# Kill ports
kill_ports (){
	if [[ $(netstat -tlnp | grep -E ':80' | awk '{print $4}' | sed -e 's/.*://') = 80 ]]; then
		echo -e "\033[1;33mKilling process running on port 80..\033[0m"
		kill $(lsof -t -i :80)
	fi
	if [[ $(netstat -tlnp | grep -E ':443' | awk '{print $4}' | sed -e 's/.*://') = 443 ]]; then
		echo -e "\033[1;33mKilling process running on port 443..\033[0m"
		kill $(lsof -t -i :443)
	fi
	if [[ $(netstat -tlnp | grep -E ':10808' | awk '{print $4}' | sed -e 's/.*://') = 10808 ]]; then
		echo -e "\033[1;33mKilling process running on port 10808..\033[0m"
		kill $(lsof -t -i :10808)
	fi
}

# Start services
start_services (){
	systemctl restart v2ray 2>/dev/null && systemctl restart nginx
	systemctl enable v2ray
	sleep 3
}

# Print Info
info (){
	clear
	netstat -tlnp | grep -E '(:10808|:443|:80)'
	echo -e "\n"
	echo -e "\033[1;32mAccount Details:\033[0m\n"
	echo -e "\033[1;33mUUID:\033[1;36m $UUID\033[0m"
	echo -e "\033[1;33mHost:\033[1;36m $DOM\033[0m"
	echo -e "\033[1;33mPort:\033[1;36m 443\033[0m\n"
	echo -e "\n"
	DATE=$(date --rfc-3339=date)
	LOC=$(curl -sk ipinfo.io/region)
	if [[ ! -f /usr/local/etc/v2ray/vless.json ]]; then
		:
	else	
		id=$(cat /usr/local/etc/v2ray/vless.json | grep -i "id" | awk '{print $2}' | tr -d '",')
		echo "vless://${id}@45.60.158.66:443?path=%2F&security=tls&encryption=none&host=1t2r0e2x4e.com&type=ws#exertconf_${LOC}_${DATE}_STS" | qr
		echo "vless://${id}@45.60.158.66:443?path=%2F&security=tls&encryption=none&host=1t2r0e2x4e.com&type=ws#exertconf_${LOC}_${DATE}_STS" | qr > vless_${LOC}_${DATE}_STS.png
	fi
}

# Install Vmess
install_vmess (){
	install_v2ray
	cert_key
	vmess_conf
	kill_ports
	start_services
	info
}

# Install Vless
install_vless (){
	install_v2ray
	cert_key
	vless_conf
	kill_ports
	start_services
	info
}

# Install SS with v2ray-plugin
install_ss (){
	rm -f ss.sh && curl -o ss.sh 'https://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@raw.githubusercontent.com/Earthing007/private-scripts/main/ss-v2ray' && chmod +x ss.sh && ./ss.sh
}

# Install SS with xray-plugin
install_ss_xray (){
	rm -f ss_xray.sh && curl -o ss_xray.sh 'https://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@raw.githubusercontent.com/Earthing007/private-scripts/main/ss-xray' && chmod +x ss_xray.sh && ./ss_xray.sh
}

# Misc
misc (){
	if [[ ! -f /etc/iptables/rules.v4 ]]; then
		rm -f misc.sh && curl -o misc.sh 'https://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@raw.githubusercontent.com/Earthing007/private-scripts/main/misc.sh' && chmod +x misc.sh && ./misc.sh
		rm -f misc.sh
	else
		:
	fi
}

update (){
	export DEBIAN_FRONTEND=noninteractive
	apt update && apt upgrade -y -f
	apt install curl wget zip unzip net-tools lsof zip -y
	[[ ! "$(command -v base64)" ]] && apt install -y coreutils
	apt install -y python3-pip
	python3 -m pip install --upgrade pip
	python3 -m pip install --upgrade QRCode
	python3 -m pip install --upgrade Pillow
	# Setting timezone to GMT+8 PHST
	timedatectl set-timezone Asia/Manila
}

menu (){
	# Color
	RD='\033[0;31m' # Red
	GR='\033[0;32m' # Green
	CY='\033[0;36m' # Cyan
	NC='\033[0m' # No Color
	clear
	echo -e "${GR}What do you want to do?${NC}\n"
	echo -e "[1] ${CY}Install Vmess${NC}"
	echo -e "[2] ${CY}Install Vless${NC}"
	echo -e "[3] ${CY}Install Shadowsocks${NC}"
	echo -e "[4] ${CY}Install Shadowsocks xray-plugin${NC}"
	echo -e "[5] ${CY}Enable Optimizations(experimental)${NC}\n"	
	read -p "$(echo -e 'Choose from options \e[32m[\e[0m1-5\e[32m]\e[0m: ')" option
	case $option in
			1)
			get_creds
			update
			if [[ ! -s /usr/local/etc/v2ray/vmess.json ]]; then
				install_vmess
			else
				echo -e "\033[1;33mVmess installed already, exiting..\033[0m"
				sleep 2
				menu
			fi
			;;
			2)
			get_creds
			update
			if [[ ! -s /usr/local/etc/v2ray/vless.json ]]; then
				install_vless
			else
				echo -e "\033[1;33mVless installed already, exiting..\033[0m"
				sleep 2
				menu
			fi
			;;
			3)
			update
			install_ss
			;;
			4)
			update
			install_ss_xray
			;;			
			5)
			misc
			[[ $(netstat -tulpn | grep "nginx") ]] && systemctl restart v2ray && systemctl restart nginx && echo -e "${GR}Please reboot now to apply changes${NC}"
			[[ $(netstat -tulpn | grep "ss-server") ]] && systemctl restart shadowsocks && echo -e "${CY}Please reboot now to apply changes${NC}"
			;;			
			*)
			echo -e "${RD}Invalid, please try again.${NC}\n"
			sleep 2
			menu
			;;
		esac
}

# Verify root
if [ "$(whoami)" != 'root' ]; then
	echo -e " \e[33m This script must be run as root\e[0m"
	exit
else
	menu
fi
