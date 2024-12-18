#!/bin/bash

# update and install dependencies
update (){
	export DEBIAN_FRONTEND=noninteractive
	apt update
	apt autoremove --fix-missing -y -f
	apt upgrade -y
	apt install -y build-essential cmake libgif-dev libpng-dev libjpeg-dev zlib1g-dev net-tools libsasl2-dev
	# compile and build libjasper
	latest_version=$(wget -qO- 'https://api.github.com/repos/jasper-software/jasper/releases/latest' | grep 'name' | grep 'version' | awk '{print $2}' | sort -u | tr -d '",')
	download_url=$(wget -qO- 'https://api.github.com/repos/jasper-software/jasper/releases/latest' | grep 'browser_download_url' | awk '{print $2}' | tr -d '"')
	wget -O jasper-${latest_version}.tar.gz $download_url
	tar xf jasper-${latest_version}.tar.gz && rm -f jasper-${latest_version}.tar.gz
	jasper_dir=$(ls | grep -v 'tar' | grep 'jasper-')
	mkdir -p ~/jasper-build
	SOURCE_DIR=~/$jasper_dir
	INSTALL_DIR=/usr
	BUILD_DIR=~/jasper-build
	OPTIONS=
	cmake -G "Unix Makefiles" -H$SOURCE_DIR -B$BUILD_DIR -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR $OPTIONS
	cd $BUILD_DIR
	make clean all
	make install
}

install_ziproxy (){
	sleep 1
	echo -e "\033[0;33m[Info]\033[0m Starting to install ziproxy.."
	wget -qO ziproxy-latest.tar.bz2 'https://sourceforge.net/projects/ziproxy/files/latest/download'
	tar xf ziproxy-latest.tar.bz2
	ziproxy_dir=$(ls | grep -v 'tar' | grep 'ziproxy-')
	pushd $ziproxy_dir
	./configure --with-jasper --with-sasl2
	make
	make install
	popd
}

configure (){
	sleep 1
	echo -e "\033[0;33m[Info]\033[0m Creating ziproxy config files.."
	mkdir /etc/ziproxy
	mkdir /var/log/ziproxy
	adduser --system --shell /usr/sbin/nologin --no-create-home ziproxy
	groupadd ziproxy
	usermod -g ziproxy ziproxy
	randomuser=$(tr -dc A-Za-z < /dev/urandom | head -c 5)
	randompass=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 8)
	echo "$randomuser:$randompass" >> /etc/ziproxy/http.passwd
	cat <<'EOF' > /etc/ziproxy/ziproxy.conf
Port = 8084
PIDFile = "/var/run/ziproxy.pid"
RunAsUser = "ziproxy"
RunAsGroup = "ziproxy"
ErrorLog = "/var/log/ziproxy/error.log"
AccessLog = "/var/log/ziproxy/access.log"
AuthMode = 1
AuthPasswdFile = "/etc/ziproxy/http.passwd"
# AuthSASLConfPath = "/etc/ziproxy/sasl/"
Nameservers = { "1.1.1.1", "1.0.0.1" }
RedefineUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"
UseContentLength = false
ProcessHTML = true
ProcessCSS = true
ProcessJS = true
ProcessHTML_CSS = true
ProcessHTML_JS = true
ProcessHTML_tags = true
ProcessHTML_text = true
ProcessHTML_PRE = true
ProcessHTML_NoComments = true
ProcessHTML_TEXTAREA = true
AllowLookChange = true
ConvertToGrayscale = true
ImageQuality = {10,5,5,3}

# Can be used as ad-block (HTTP only) #
# URLReplaceDataCT = "/etc/ziproxy/replace_ct.list"
# URLReplaceDataCTList = {"image/jpeg", "image/gif", "image/png", "application/x-shockwave-flash"}
# URLReplaceDataCTListAlsoXST = true

# Block bad URLs #
# URLDeny = "/etc/ziproxy/deny.list"

# JPEG 2000-specific options (require Ziproxy to be compiled with libjasper) #
ProcessJP2 = true
ForceOutputNoJP2 = true
JP2ImageQuality = {10,5,5,3}
EOF


# Create systemd service
	cat <<'EOF' > /etc/systemd/system/ziproxy.service
[Unit]
Description=Ziproxy Daemon Service
After=network.target

[Service]
Type=forking
PIDFile=/var/run/ziproxy.pid
ExecStart=/usr/local/bin/ziproxy -d
ExecStop=/usr/local/bin/ziproxy -k

[Install]
WantedBy=multi-user.target
EOF
}

start_service (){
	sleep 1
	echo -e "\033[0;33m[Info]\033[0m Starting ziproxy.."
	sleep 2
	systemctl daemon-reload
	systemctl start ziproxy
	systemctl enable ziproxy
	if [[ $(netstat -tulpn | grep -c 'ziproxy') != 1 ]]; then
		echo -e "\033[1;31m[Error]\033[0m Ziproxy failed to start, exiting.."
		sleep 1 && exit 1
	fi
}

print_info (){
	clear
	echo ""
	echo -e "\033[1;32m[Ok]\033[0m Installation success!\n"
	echo -e "Ziproxy IP Address: \033[1;32m$(wget -4qO- ipinfo.io/ip)\033[0m"
	echo -e "Ziproxy Port: \033[1;32m$(netstat -tulpn | grep 'ziproxy' | awk '{print $4}' | sed -e 's/.*://')\033[0m"
	echo -e "\033[0;33mAuthentication Details:\033[0m"
	echo -e "Username : \033[1;32m$randomuser\033[0m"
	echo -e "Password : \033[1;32m$randompass\033[0m"	
	echo -e "\n"
}

clean (){
	rm -rf ~/jasper-2.0.32
	rm -f ~/install-ziproxy.sh
}

install (){
	update
	install_ziproxy
	configure
	start_service
	print_info
	clean
}

remove (){
	[[ ! $(command -v netstat) ]] && apt install net-tools
	ziproxy_port=$(netstat -tulpn | grep 'ziproxy' | awk '{print $4}' | sed -e 's/.*://')
	[[ ! $(command -v lsof) ]] && apt install -y lsof
	kill $(lsof -t -i :${ziproxy_port}) > /dev/null
	systemctl daemon-reload
	rm -rf /etc/ziproxy
	rm -f /usr/local/bin/ziproxy
	rm -rf ~/ziproxy*
	rm -r ~/jasper*
	rm -f /usr/local/bin/ziproxylogtool
	rm -f /usr/local/share/man/man1/ziproxy.1
	rm -f /usr/local/share/man/man1/ziproxylogtool.1
	rm -r /var/log/ziproxy
	rm -f /etc/systemd/system/multi-user.target.wants/ziproxy.service
	rm -f /etc/systemd/system/ziproxy.service
	systemctl daemon-reload
	echo -e "\033[0;33m[Info]\033[0m Ziproxy removed, done."
	rm -f ~/install-ziproxy.sh
}

menu (){
	clear
	echo -e "\033[1;32mWhat do you want to do?\033[0m\n"
	echo -e "[1] \033[0;33mInstall\033[0m"
	echo -e "[2] \033[0;33mRemove\033[0m"
	read -p "$(echo -e 'Choose from options \033[1;32m[\033[0m1-2\033[1;32m]\033[0m: ')" option
		case $option in
			1)
			install
			;;
			2)
			remove
			;;
			*)
			echo -e "\033[1;31mInvalid, please try again.\033[0m\n"
			sleep 2
			menu
			;;
		esac
}

check_system (){
	os=$(grep "^ID=" /etc/os* | awk -F '=' '{print $2}')
	if [[ $os == ubuntu ]] || [[ $os == debian ]]; then
		menu
	else
		echo -e "\033[1;31m[Error]\033[0m Please run on Ubuntu or Debian only."
		exit 1
	fi
}

# Verify root
if [[ $(whoami) == root ]]; then
	check_system
else
	echo -e "\033[1;31m[Error]\033[0m You must be logged-in as root before running this script."
	exit 1
fi
