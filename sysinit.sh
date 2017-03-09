#!/bin/bash
#
# Author: Xu Panda
# Update: 2016-09-09
#
# system initialize
#

DIR=$(cd `dirname $0`;echo $PWD) && cd $DIR

## repos:
yum -q update centos-release -y;yum -q install epel-release -y;yum -q clean all;yum -q update -y

## necessary software
yum install make cmake gcc python vim \
		tcpdump iftop sysstat bind-utils traceroute screen lrzsz xinetd rsync net-snmp-utils\
		openssl openssl-devel mhash mhash-devel compat-libstdc++-33 \
		libmcrypt libmcrypt-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel pcre pcre-devel libevent libevent-devel \
		sl sipcalc \
		jwhois tree \
		redhat-lsb-core \
		-y -q

## get version
VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release)
if [ $VERSION -ge 7 ];then
	LANG_FILE="/etc/locale.conf"
	SERVICE_CONTROL="systemctl"
else
	LANG_FILE="/etc/sysconfig/i18n"
	SERVICE_CONTROL="service"
fi

## langure charset
if [ $(grep "^LANG=" $LANG_FILE | awk -F '"' '{print $2}') != "en_US.UTF-8" ];then
	sed -ri '/^LANG=.*/ s//LANG="en_US.UTF-8"/' $LANG_FILE
fi

## ntp sync time
yum -q install ntp ntpdate -y
$SERVICE_CONTROL stop ntpd &> /dev/null
ntpdate 0.asia.pool.ntp.org > /dev/null
$SERVICE_CONTROL start ntpd &> /dev/null
chkconfig ntpd on &> /dev/null
systemctl enabled ntpd &> /dev/null

## Disable selinux
if sestatus | grep enable;then
	setenforce 0 > /dev/null
	sed -ri '/^SELINUX=\w+$/ s//SELINUX=disabled/' /etc/selinux/config
fi

## Disable iptables
$SERVICE_CONTROL stop firewalld &> /dev/null
chkconfig iptables off &> /dev/null
systemcto disable firewalld &> /dev/null

## kenerl
SYSCTL=/etc/sysctl.conf
if ! grep -q "tcp_tw_reuse" /etc/sysctl.conf;then
	echo "net.ipv4.tcp_tw_reuse = 1" >> $SYSCTL
fi
if ! grep -q "tcp_tw_recycle" /etc/sysctl.conf;then
	echo "net.ipv4.tcp_tw_recycle = 1" >> $SYSCTL
fi
if ! grep -q "tcp_fin_timeout" /etc/sysctl.conf;then
	echo "net.ipv4.tcp_fin_timeout = 30" >> $SYSCTL
fi
modprobe ip_conntrack
if ! grep -q "net.nf_conntrack_max" /etc/sysctl.conf;then
	echo "net.nf_conntrack_max = 65535000" >> /etc/sysctl.conf
fi
sysctl -p > /dev/null

## Shutdown unnecessary services
if [ $VERSION -lt 7 ];then
	for p in $(chkconfig --list | awk '$1!~/aegis|xinetd|winbind|smb|ntpd|crond|snmpd|network|syslog|sshd|tunnel|psacct/ && $5~/on/ {print $1}');do
		$SERVICE_CONTROL stop $p &> /dev/null
		chkconfig $p off &> /dev/null
	done
else
	for p in $(systemctl list-unit-files | grep enabled | awk '$1!~/aliyun|crond|aegis|xinetd|winbind|smb|ntpd|snmpd|ntpd|rsyslog|sshd|sysstat|systemd|default|multi-user/ {print $1}');do
		$SERVICE_CONTROL stop $p
		systemctl disable $p
	done
fi

## Mkdir
ROOT=/ROOT && mkdir -p $ROOT && cd $ROOT
mkdir -p www tmp server logs src BACKUP sh/CRON data conf bin
chmod 700 BACKUP
chmod 777 tmp && chmod o+t tmp
chmod 750 sh
if ! grep -q '/ROOT/bin' /etc/profile;then
	echo 'export PATH=/ROOT/bin:$PATH' >> /etc/profile
	source /etc/profile
fi
cd $DIR

## modify logrotate time to 23:59
if [ -f /etc/cron.daily/logrotate ];then
	mv /etc/cron.daily/logrotate /ROOT/sh/CRON
fi
cat > /etc/cron.d/logrotate << EOF
# logrotate
59 23 * * * root sh /ROOT/sh/CRON/logrotate
EOF

## disable updatedb
sed -i '2,$s/^/#/' /etc/cron.daily/mlocate.cron &> /dev/null

## dns resolv timeout
if ! grep -q 'options timeout' /etc/resolv.conf;then
	sed -i '1ioptions timeout:5 attempts:1 rotate' /etc/resolv.conf
fi

echo -e "\n\e[32mDon't forget to reboot your system!\nRun:\n\nshutdown -r now\n\e[0m"
