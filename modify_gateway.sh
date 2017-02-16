#!/bin/bash
#

# Author: Panda
# Update: 20160612

# modify host gateway

## define which net will add
new_nets="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"

## define gateway
def_gateway () {
	if [ $location == "cnc" ];then
		gw="10.0.0.254"
	elif [ $location == "ctc" ];then
		gw="10.1.0.254"
	elif [ $location == "bgp" ];then
		gw="10.2.0.254"
	fi
}

## define location ip netmask
nets="cnc_net ctc_net bgp_net"
cnc_net="10.0.0.0/16"
ctc_net="10.1.0.0/16"
bgp_net="10.2.0.0/16"

## get private ip address
private_ip=$(/sbin/ip add | grep 'inet ' | \
		awk '{print $2}' | \
		egrep '^(10\.|172\.1[7-8])' \
	    )

## get location
calc_ip () {
	for pip in $private_ip;do
		if which ipcalc &> /dev/null;then
			if [ $(ipcalc -n $pip) == $(ipcalc -n $mynet) ];then
				location=${net%_net}
				break_key=1
				break
			fi
		else
		#	ip_head=$(echo $pip | awk -F'.' '{print $1"."$2}')
		#	if [ $(echo $mynet | grep $ip_head | wc -l) = 1 ];then
		#		location=${net%_net}
		#		break_key=1
		#		break
		#	fi
			echo -e "\e[31;5mHelp me to install \e[32mipcalc\e[0m\nyum -y install sipcalc\nthen run me again."
			yum -yq install sipcalc
			exit 2
		fi
		if [ $break_key -eq 1 ];then
			private_ip=$pip
			break
		fi
	done
}
get_location () {
	location=""
	break_key=0
	for net in $nets;do
		eval realnet="\$$net"
		for mynet in $realnet;do
			calc_ip
		done
		if [ $break_key -eq 1 ];then
			break
		fi
	done
	if [ -z $location ];then
		echo -e "\e[31m$private_ip\e[0m not in \e[32mnets\e[0m"
		exit 2
	fi
}

## get route file
ifcfg=$(/sbin/ip add | grep ^2 | awk '{print $2}' | sed 's/://')
route_file=/etc/sysconfig/network-scripts/route-$ifcfg

## do add route
retVal=0
inc_retVal () {
	if [ $? -ne 0 ];then
		retVal=$[$retVal+1]
	fi
}
add_route () {
	for net in $new_nets;do
		if /sbin/ip route | grep -q $net;then
			sudo /sbin/ip route del $net
			inc_retVal
		fi
		sudo /sbin/ip route add $net via $gw
		inc_retVal

		sudo touch $route_file
		if ! grep -q $net $route_file;then
			sudo sh -c "echo \"$net via $gw\" >> $route_file"
			inc_retVal
		else
			network=$(echo $net | awk -F'/' '{print $1}')
			mask=$(echo $net | awk -F'/' '{print $2}')
			sudo sed -i "/^${network}\/${mask}/s/.*/${network}\/${mask} via $gw/" $route_file
			inc_retVal
		fi
	done
	if [ $retVal -gt 0 ];then
		echo -e "\e[31mroute add maybe failed!\e[0m"
		exit 2
	fi
}

get_location
def_gateway
## this if is unnecessary
if [ $(/sbin/ip route | egrep '^(10\.0\.0\.0\/8|172\.16\.0\.0\/12|192\.168\.0\.0\/16)' | wc -l) -gt 0 ];then
	#echo "my ip is $private_ip"
	/sbin/ip route | egrep '^(10\.0\.0\.0\/8|172\.16\.0\.0\/12|192\.168\.0\.1\/17)' > /tmp/oldroute
	#exit 2
fi
add_route
