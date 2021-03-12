#!/bin/bash

rd=$'\033[31m'; # Red
gr=$'\033[32m'; # Green
or=$'\033[33m'; # Orange
pr=$'\033[35m'; # Purple
cy=$'\033[36m'; # Cyan
nc=$'\033[0m'; # No Color
#bg-colors
rdbg=$'\033[41m'; # Red background
blbg=$'\033[44m'; # Blue background

opt1=$'\033[35m[\033[0m1\033[35m]\033[0m';
opt2=$'\033[35m[\033[0m2\033[35m]\033[0m';
opt3=$'\033[35m[\033[0m3\033[35m]\033[0m';
opt4=$'\033[35m[\033[0m4\033[35m]\033[0m';
opt5=$'\033[35m[\033[0m5\033[35m]\033[0m';
opt6=$'\033[35m[\033[0m6\033[35m]\033[0m';
opt7=$'\033[35m[\033[0m7\033[35m]\033[0m';
opt8=$'\033[35m[\033[0m8\033[35m]\033[0m';

banner (){
	clear
	echo -e ""
	echo " ============================="
	echo "[${blbg}          EXERTVPN           ${nc}]"
	echo " ============================="
	echo -e "\n"
}

return (){
	echo "$opt1 Return to menu"
	echo "$opt2 Exit/Cancel"
	echo ""
	read -p "choose from options --> " return
	clear
	case $return in
		1)
		menu
		;;
		2)
		clear
		exit
		;;
	esac
}
