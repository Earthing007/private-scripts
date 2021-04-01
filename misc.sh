#!/bin/bash

# Verify root
if [ "$(whoami)" != 'root' ]; then
	echo -e " \e[33m This script must be run as root\e[0m"
	exit
fi

#Vars
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1);
NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1);

export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y -f
apt install -y unzip iptables-persistent fail2ban vnstat net-tools ipset

# Fail2ban
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl restart fail2ban

# Iptables
cat >> /etc/iptables/rules.v4 << END
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:f2b-sshd - [0:0]
-A INPUT -p tcp -m multiport --dports 22 -j f2b-sshd

-A INPUT -i $NIC -p tcp -m state --state NEW,ESTABLISHED --dport 22 -j ACCEPT
-A INPUT -i $NIC -p udp -m state --state NEW,ESTABLISHED --dport 53 -j ACCEPT
-A INPUT -i $NIC -p tcp -m state --state NEW,ESTABLISHED --dport 443 -j ACCEPT

#Torrent
-A FORWARD -p tcp -i $NIC --dport 6881:6889 -d $IP -j REJECT
-A OUTPUT -p tcp --dport 6881:6889 -j DROP
-A OUTPUT -p udp --dport 6881:6889 -j DROP

-A INPUT -p tcp -m tcp --dport 25 -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "BitTorrent" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "BitTorrent protocol" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "peer_id=" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string ".torrent" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "announce.php?passkey=" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "torrent" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "announce" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "info_hash" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "find_node" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --algo bm --string "get_peers" -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "BitTorrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "BitTorrent protocol" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "peer_id" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string ".torrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "announce.php?passkey=" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "torrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "announce" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "info_hash" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "find_node" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -m string --string "get_peers" --algo kmp -j REJECT --reject-with icmp-port-unreachable

-A FORWARD -p tcp -m tcp --dport 25 -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "BitTorrent" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "BitTorrent protocol" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "peer_id=" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string ".torrent" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "announce.php?passkey=" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "torrent" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "announce" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "info_hash" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "find_node" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --algo bm --string "get_peers" -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "BitTorrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "BitTorrent protocol" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "peer_id" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string ".torrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "announce.php?passkey=" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "torrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "announce" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "info_hash" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "find_node" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A FORWARD -m string --string "get_peers" --algo kmp -j REJECT --reject-with icmp-port-unreachable

-A OUTPUT -p tcp -m tcp --dport 25 -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "BitTorrent" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "BitTorrent protocol" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "peer_id=" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string ".torrent" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "announce.php?passkey=" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "torrent" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "announce" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "info_hash" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "find_node" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --algo bm --string "get_peers" -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "BitTorrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "BitTorrent protocol" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "peer_id" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string ".torrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "announce.php?passkey=" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "torrent" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "announce" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "info_hash" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "find_node" --algo kmp -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -m string --string "get_peers" --algo kmp -j REJECT --reject-with icmp-port-unreachable

# PortScan_protection
-A INPUT -m state --state INVALID -j DROP
-A INPUT -m state --state NEW -m set ! --match-set scanned_ports src,dst -m hashlimit --hashlimit-above 1/hour --hashlimit-burst 5 --hashlimit-mode srcip --hashlimit-name portscan --hashlimit-htable-expire 10000 -j SET --add-set port_scanners src --exist
-A INPUT -m state --state NEW -m set --match-set port_scanners src -j DROP
-A INPUT -m state --state NEW -j SET --add-set scanned_ports src,dst

-A f2b-sshd -j RETURN

-A INPUT -j DROP
COMMIT
END
sed -i "s/xxxxxxxxx/$IP/" /etc/iptables/rules.v4

cat >> /etc/systemd/system/ipset-persistent.service << END
[Unit]
Description=ipset persistent configuration
Before=network.target

# ipset sets should be loaded before iptables
# Because creating iptables rules with names of non-existent sets is not possible
Before=netfilter-persistent.service
Before=ufw.service

ConditionFileNotEmpty=/etc/iptables/ipset

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ipset restore -file /etc/iptables/ipset
# Uncomment to save changed sets on reboot
ExecStop=/sbin/ipset save -file /etc/iptables/ipset
ExecStop=/sbin/ipset flush
ExecStopPost=/sbin/ipset destroy

[Install]
WantedBy=multi-user.target

RequiredBy=netfilter-persistent.service
RequiredBy=ufw.service
END

ipset create port_scanners hash:ip family inet hashsize 32768 maxelem 65536 timeout 600
ipset create scanned_ports hash:ip,port family inet hashsize 32768 maxelem 65536 timeout 60
ipset save > /etc/iptables/ipset

systemctl daemon-reload
systemctl enable ipset-persistent.service

iptables-restore < /etc/iptables/rules.v4
netfilter-persistent save
systemctl enable netfilter-persistent

# Install speedtest by ookla
apt-get install -y gnupg1 apt-transport-https dirmngr
export INSTALL_KEY=379CE192D401AB61
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $INSTALL_KEY
echo "deb https://ookla.bintray.com/debian generic main" | tee  /etc/apt/sources.list.d/speedtest.list
apt-get update
# Other non-official binaries will conflict with Speedtest CLI
# Example how to remove using apt-get
# sudo apt-get remove speedtest-cli
apt-get install speedtest

# BBR
kernel=$(uname -r | awk -F- '{print $1}' | tr -d '.')
checkBBR () {
	if [[ $(sysctl net.ipv4.tcp_congestion_control | awk -F= '{print $2}') = " bbr" ]]; then
		return 0
	else
		return 1
	fi
}
checkBBR
if [[ $? -eq 0 ]]; then
	echo -e "\e[1;33mTCP BBR already enabled\e[0m"
elif [[ $kernel -lt 490 ]]; then
	echo -e "\e[1;31mKernel 4.9 or above is required to enable TCP BBR\e[0m"
else
	sed -i '/net.core.default_qdisc*/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_congestion_control*/d' /etc/sysctl.conf
	echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sysctl -p >/dev/null 2>&1
	checkBBR
	if [[ $? -eq 0 ]]; then
		echo -e "\e[1;32mTCP BBR enabled successfully.\e[0m"
	else
		echo -e "\e[1;31mFailed to enable TCP BBR.\e[0m"
	fi
fi

# Kernel Optimizations
if [[ ! -f /proc/sys/net/ipv4/tcp_tw_recycle ]]; then
echo "fs.file-max = 51200
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864" >> /etc/sysctl.conf
sysctl -p
else
echo "fs.file-max = 51200
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864" >> /etc/sysctl.conf
sysctl -p
fi

if [[ $(ulimit -aH | grep "open files" | awk '{print $4}') -lt 51200 ]]; then
echo "* soft nofile 51200
* hard nofile 51200" >> /etc/security/limits.conf
else
:
fi

echo "session required pam_limits.so" >> /etc/pam.d/common-session
echo "ulimit -n 51200" >> /etc/profile
ulimit -n 51200

# Setting timezone to GMT+8 PHST
timedatectl set-timezone Asia/Manila

mkdir /etc/exert
curl -kL "https://gist.githubusercontent.com/Earthing007/af7f138077e0a7e67d96b3e3f5797d42/raw/clear_cache.sh" -o /etc/exert/clear_cache.sh && chmod +x /etc/exert/clear_cache.sh

# Cron
crontab -l > mycron
echo "*/5 * * * * /etc/exert/clear_cache.sh >/dev/null 2>&1" >> mycron
crontab mycron
rm mycron
systemctl enable cron && systemctl restart cron
