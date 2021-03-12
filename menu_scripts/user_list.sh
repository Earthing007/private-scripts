#!/bin/bash
source /usr/local/sbin/base

if [ -f /etc/debian_version ]; then
	UIDN=1000
elif [ -f /etc/redhat-release ]; then
	UIDN=500
else
	UIDN=500
fi

banner
echo "          Users list"
echo ""
echo " ${rdbg}Username${nc}     |      ${rdbg}Expiration${nc}"
echo ""
while read Checklist
do
        Spacer=""
        Account="$(echo $Checklist | cut -d: -f1)"
        ID="$(echo $Checklist | grep -v nobody | cut -d: -f3)"
        Exp="$(chage -l $Account | grep "Account expires" | awk -F": " '{print $2}')"
        if [[ $ID -ge $UIDN ]]; then
        echo -e " $Account   " "   $Exp"
        fi
done < /etc/passwd
No_Users="$(awk -F: '$3 >= '$UIDN' && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
echo ""
echo " Number of Users: ${or}"$No_Users${nc}
echo -e "\n"
return