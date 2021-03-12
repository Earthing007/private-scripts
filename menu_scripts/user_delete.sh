#!/bin/bash
source /usr/local/sbin/base

banner
read -p " Enter the username: " User
echo ""
sleep 2
egrep "^$User" /etc/passwd &> /dev/null
if [ $? -eq 0 ]; then
	userdel -f $User
	rm -rf /home/$User
	clear
	echo ""
	banner
	echo " User Deleted!"
	echo "\n"
	return
else
	clear
	banner
	echo " User you entered does not exist."
	echo "\n"
	return
fi
