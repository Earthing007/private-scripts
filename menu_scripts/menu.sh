#!/bin/bash
source /usr/local/sbin/base


banner
echo "$opt1 Create Account"
echo "$opt2 List Users"
echo "$opt3 Delete User"
echo "$opt4 Show Ports"
echo "$opt5 Show RAM usage"
echo "$opt6 Exit/Cancel"
echo ""
read -p "choose from options --> " menu
sleep 0.5
clear
	case $menu in
			1)
			clear
			create
			exit
			;;
			2)
			clear
			user_list
			exit
			;;
			3)
			clear
			user_delete
			exit
			;;
			4)
			clear
			ports
			exit
			;;		
			5)
			clear
			ram
			exit
			;;
			6)
			clear
			exit
			;;
	esac
