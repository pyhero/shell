#!/bin/bash
#

getpass () {
	local len=8
	rpass=""
	local ary=(	0 1 2 3 4 5 6 7 8 9 \
		a b c d e f g h i j k l m n o p q r s t u v w x y z \
		A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
	    )
	for ((i=1;i<=$len;i++));do
		rpass=${rpass}${ary[$RANDOM % ${#ary[*]}]}
	done
	statime=$(date "+%F %T")
	endtime=$(date -d '+5 minutes' "+%F %T")
}

getuser () {
	local group=openvpn
	local cmd=$(which wbinfo 2> /dev/null)
	[ ! $cmd ] && echo "no wbinfo command." && exit 2
	users=$($cmd --group-info=$group | awk -F':' '{print $NF}' | sed 's/\,/ /g')
}

host="10.9.1.77"
port="3314"
username="ovpn"
password="uoVPyxY8"

mysql=$(which mysql 2> /dev/null)
[ ! $mysql ] && echo -e "Install mysql:\n\tyum install mysql -y" && exit 2
#dosql="$mysql -N -s -u${username} -p${password} -h${host} -P ${port}"
dosql="mysql -N -s -u${username} -p${password}"

chkuid () {
	$dosql -e"use ovpn;select u_id from user where u_id='${u}';"
}
getuid () {
	$dosql -e"use ovpn;select u_id from user;"
}
insuid () {
	$dosql -e"use ovpn;insert into user(u_id,u_pass,u_start,u_end) values('${u}','${rpass}','${statime}','${endtime}');"
}
repass () {
	$dosql -e"use ovpn;update user set u_pass='${rpass}',u_start='${statime}',u_end='${endtime}' where u_id='${u}';"
}
deluid () {
	$dosql -e"use ovpn;update user set u_enable=0 where u_id='${u}';"
}

renew () {
	getuser
	#users="panda hh xx a"
	for u in $users;do
		getpass
		rev=$(chkuid)
		if [ ! $rev ];then
			insuid
		else
			repass
		fi
	done
}

delold () {
	uidtmp=/tmp/ovpnuid
	usrtmp=/tmp/ldapusr
	getuid | sort > $uidtmp
	getuser && echo $users | sed 's/ /\n/g' | sort > $usrtmp
	for ouid in $uidtmp;do
		grep -q $ouid $usrtmp
		if [ $? -ne 0 ];then
			u=$ouid
			deluid
		fi
	done
}
