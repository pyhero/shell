#!/bin/bash
#
# Author: Xu Panda
# Update: 2015-08-11

help () {
	echo -e "Useage:$0 -H <host> -i <interface> -w <warn value> -c <crit value> [-V <snmp version>] [-C <snmp community>] \n \
		-H, name or IP address of host to check \n \
		-i, interface of host to check \n \
		-w, traffic warning value,unit: [K|M] \n \
		-c, traffic critical value,unit: [K|M] \n \
		    For example: \n \
		    -w 200K -c 200K \n \
		    -w 200M -c 200M \
		"
	exit 3
}

if [ $# -lt 8 ];then
	help
fi

OK=0
WAR=1
CRI=2
UNK=3

while getopts H:i:w:c::v::C:h opt;do
	case $opt in
		H)
			HOST=$OPTARG
			;;
		i)
			INTERFACE=$OPTARG
			intfile=$(echo $INTERFACE|sed 's/\//\./;s/ //')
			echo $INTERFACE | egrep '\ ' > /dev/null
			if [ $? -ne 0 ];then
				INTERFACE=$(echo $INTERFACE | sed 's/Ethernet/Ethernet /')
			fi
			;;
		w)
			warn=$OPTARG
			;;
		c)
			crit=$OPTARG
			;;
		v)
			snmp_ver=$OPTARG
			;;
		C)
			snmp_com=$OPTARG
			;;
		h|*)
			help
	esac
done
[ ! $snmp_ver ] && snmp_ver="2c"
[ ! $snmp_com ] && snmp_com="PaxX2099clv2"

filing () {
	tmp=/tmp
	if [ ! -w $tmp ];then
		echo "$tmp:temp data directory is not writeable for nagios!"
		exit $UNK
	fi
	tmpfile=$tmp/$HOST-$intfile.snmp
	if [ ! -f $tmpfile ];then
		touch $tmpfile
	elif [ ! -w $tmpfile ];then
		echo "run: rm $tmpfile $tmpfile.ago"
		exit $UNK
	fi
	mv $tmpfile $tmpfile.ago
}

timing () {
	nowtiming=$(date "+%s")
	echo $nowtiming >> $tmpfile
}

get_data () {
	get_com=$(which snmpget 2> /dev/null)
	wal_com=$(which snmpwalk 2> /dev/null)
	if [ -z $get_com -o -z $wal_com ];then
		echo "Install snmpwalk & snmpget first!"
		echo "		yum install -y net-snmp-utils"
		exit $UNK
	fi
	if_num=$($wal_com -v $snmp_ver -c $snmp_com $HOST ifDescr | \
			grep -i "$INTERFACE" | grep -Po '(?<=ifDescr\.).*(?=\ \=)' \
		)
	if [ -z $if_num ];then
		echo "$INTERFACE: not exits!"
		exit $UNK
	fi
	get_info="ifInOctets.$if_num ifOutOctets.$if_num"
	filing
	$get_com -v $snmp_ver -c $snmp_com $HOST $get_info > $tmpfile
	timing
}

dating () {
	get_data
	rev=0
	if [ ! -s $tmpfile.ago ];then
		rev=1
	else
		lastifin=$(cat $tmpfile.ago | grep -i ifin | awk '{print $NF}')
		lastifout=$(cat $tmpfile.ago | grep -i ifout | awk '{print $NF}')
		histiming=$(tail -n1 $tmpfile.ago)
	fi
	if [ ! -s $tmpfile ];then
		rev=1
	else
		nowifin=$(cat $tmpfile | grep -i ifin | awk '{print $NF}')
		nowifout=$(cat $tmpfile | grep -i ifout | awk '{print $NF}')
		nowtiming=$(tail -n1 $tmpfile)
	fi
	if [ $rev == 1 ];then
		echo "Fighting ~ Wait for a moment!"
		exit 0
	fi
	intExp="^-?\d+$"
	if [ `echo $histiming$lastifin$lastifout$nowifin$nowifout$nowtiming | grep -P "${intExp}" | wc -l` != 1 ];then
		echo "Bad number!"
		exit $UNK
	fi

	diffifin=$[$nowifin-$lastifin]
	if [ -z $diffifin -o $diffifin -lt 0 ];then
		echo "Wrong ifin"
		#exit $UNK
		exit 0
	fi
	diffifout=$[$nowifout-$lastifout]
	if [ -z $diffifout -o $diffifout -lt 0 ];then
		echo "Wrong ifout"
		#exit $UNK
		exit 0
	fi
	mistiming=$[$nowtiming-$histiming]
	if [ -z $mistiming -o $mistiming -lt 0 ];then
		echo "Time wrong!"
		exit $UNK
	fi
	inspeed=$(echo $diffifin $mistiming | awk "{printf \"%d\n\", $diffifin/$mistiming}")
	outspeed=$(echo $diffifout $mistiming | awk "{printf \"%d\n\", $diffifout/$mistiming}")
}

nagios_data () {
	dating
	inunit=$[$inspeed/1024]
	if [ $inunit == 0 -a $inspeed -lt 1024 ];then
		echo -n "In:${inspeed}B/s "
	elif [ $inspeed == 1024 ];then
		echo -n "In:1KB/s "
	elif [ $inunit -ge 0 -a $inunit -lt 1024 ];then
		linspeed=$(echo $inspeed | awk '{printf "%.2f\n", $1/1024}')
		echo -n "In:${linspeed}KB/s "
	elif [ $inspeed == 1048576 ];then
		echo -n "In:1MB/s "
	elif [ $inunit -ge 1024 -a $inspeed -gt 1048576 ];then
		linspeed=$(echo $inspeed | awk '{printf "%.2f\n", $1/1024/1024}')
		echo -n "In:${linspeed}MB/s "
	fi

	outunit=$[$outspeed/1024]
	if [ $outunit == 0 -a $outspeed -lt 1024 ];then
		echo -n "Out:${outspeed}B/s"
	elif [ $outspeed == 1024 ];then
		echo -n "Out:1KB/s"
	elif [ $outunit -ge 0 -a $outunit -lt 1024 ];then
		loutspeed=$(echo $outspeed | awk '{printf "%.2f\n", $1/1024}')
		echo -n "Out:${loutspeed}KB/s"
	elif [ $outspeed == 1048576 ];then
		echo -n "Out:1MB/s"
	elif [ $outunit -ge 1024 -a $outspeed -gt 1048576 ];then
		loutspeed=$(echo $outspeed | awk '{printf "%.2f\n", $1/1024/1024}')
		echo -n "Out:${loutspeed}MB/s"
	fi
	echo "| In=$inspeed Out=$outspeed"
}

nagios () {
	Exp="^-?\d+[k|K|m|M]$"
	wv=$(echo $warn | grep -P "${Exp}" | wc -l)
	cv=$(echo $crit | grep -P "${Exp}" | wc -l)
	tv=$[$wv+$cv]
	if [ $tv != 2 ];then
		echo -e "\e[32m<-w $warn> or <-c $crit> wrong!\e[0m"
		help
	fi
	dovalue=$(echo $warn | sed 's/\([0-9]*\)\(.*\)/\1 \2/')
	num=$(echo $dovalue|awk '{print $1}')
	uni=$(echo $dovalue|awk '{print $2}')
	if [ `echo $uni | egrep '(k|K)' | wc -l` == 1 ];then
		mul="1024"
	elif [ `echo $uni | egrep '(m|M)' | wc -l` == 1 ];then
		mul="1024*1024"
	fi
	wb=$[$num*$mul]
	dovalue=$(echo $crit | sed 's/\([0-9]*\)\(.*\)/\1 \2/')
	num=$(echo $dovalue|awk '{print $1}')
	uni=$(echo $dovalue|awk '{print $2}')
	if [ `echo $uni | egrep '(k|K)' | wc -l` == 1 ];then
		mul="1024"
	elif [ `echo $uni | egrep '(m|M)' | wc -l` == 1 ];then
		mul="1024*1024"
	fi
	cb=$[$num*$mul]
	if [ $wb -ge $cb ];then
		echo "crit value must greater than warning value!"
		help
	fi
	nagios_data

	if [ $inspeed -gt $cb -o $outspeed -gt $cb ];then
		exit $CRI
	elif [ $inspeed -lt $cb -a $inspeed -ge $wb ];then
		exit $WAR
	elif [ $outspeed -lt $cb -a $outspeed -ge $wb ];then
		exit $WAR
	elif [ $inspeed -lt $wb -a $outspeed -lt $wb ];then
		exit $OK
	fi
}

nagios
