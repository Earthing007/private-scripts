#!/bin/bash

# update and install dependencies
update (){
	export DEBIAN_FRONTEND=noninteractive
	apt update
	apt autoremove --fix-missing -y -f
	apt upgrade -y
	apt install -y build-essential cmake libgif-dev libpng-dev libjpeg-dev zlib1g-dev net-tools
	# compile and build libjasper
	latest_version=$(wget -qO- 'https://api.github.com/repos/jasper-software/jasper/releases/latest' | grep 'name' | grep 'version' | awk '{print $2}' | sort -u | tr -d '",')
	download_url=$(wget -qO- 'https://api.github.com/repos/jasper-software/jasper/releases/latest' | grep 'browser_download_url' | awk '{print $2}' | tr -d '"')
	wget -O jasper-${latest_version}.tar.gz $download_url
	tar xf jasper-${latest_version}.tar.gz && rm -f jasper-${latest_version}.tar.gz
	jasper_dir=$(ls | grep -v 'tar' | grep 'jasper-')
	cd $jasper_dir && mkdir build
	SOURCE_DIR=~/$jasper_dir
	INSTALL_DIR=/usr
	BUILD_DIR=~/$jasper_dir/build
	OPTIONS=
	cmake -G "Unix Makefiles" -H$SOURCE_DIR -B$BUILD_DIR -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR $OPTIONS
	cd $BUILD_DIR
	make clean all
	make install
}

install_ziproxy (){
	sleep 1
	echo -e "\033[0;33m[Info]\033[0m Installing ziproxy.."
	wget -qO ziproxy-latest.tar.bz2 'https://sourceforge.net/projects/ziproxy/files/latest/download'
	tar xf ziproxy-latest.tar.bz2
	ziproxy_dir=$(ls | grep -v 'tar' | grep 'ziproxy-')
	pushd $ziproxy_dir
	./configure --with-jasper --with-sasl2=no
	make
	make install
	popd
}

configure (){
	sleep 1
	echo -e "\033[0;33m[Info]\033[0m Creating ziproxy config file.."
	mkdir /etc/ziproxy
	cat <<'EOF' > /etc/ziproxy/ziproxy.conf
Port = 8084
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
ImageQuality = {20,15,15,10}

### MAYBE USED AS ADBLOCK OPTION ####
# URLReplaceDataCT = "/etc/ziproxy/replace_ct.list"
# URLReplaceDataCTList = {"image/jpeg", "image/gif", "image/png", "application/x-shockwave-flash"}
# URLReplaceDataCTListAlsoXST = true
#####################################

### BLOCK URLS ###
# URLDeny = "/etc/ziproxy/deny.list"
##################

##############################################################################
# JPEG 2000-specific options (require Ziproxy to be compiled with libjasper) #
##############################################################################

ProcessJP2 = true
ForceOutputNoJP2 = true
JP2ImageQuality = {20,15,15,15}
EOF
}

start_service (){
	# start ziproxy in daemon-mode
	sleep 1
	echo -e "\033[0;33m[Info]\033[0m Starting ziproxy.."
	ziproxy -d --config-file=/etc/ziproxy/ziproxy.conf
	sleep 3
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
	echo -e "Ziproxy Port: $(netstat -tulpn | grep 'ziproxy' | awk '{print $4}' | sed -e 's/.*://')"
	echo -e "\n"
}

clean (){
	rm -f install-ziproxy.sh
	rm -rf jasper-2.0.32
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
	rm -rf /etc/ziproxy
	rm -f /usr/local/bin/ziproxy
	rm -rf ~/ziproxy*
	rm -r ~/jasper*
	echo -e "\033[0;33m[Info]\033[0m Ziproxy removed, done."
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