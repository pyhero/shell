#!/bin/bash
#
# Author Xu Panda
# Date 2014-08-19
#
# Change ip address to binary -> change binary to ASCII \
# find part in area.

DIR=$(cd `dirname $0`;echo $PWD)
cd $DIR
dodir=$DIR/dodir
if [ ! -d $dodir ];then
	mkdir $dodir
fi

install_netmask () {
	cd src
	tar zxf netmask_2.3.10.tar.gz && cd netmask-2.3.10
	./configure && make && make install
	cd -
}
	
# Need install <netmask> first
which netmask &> /dev/null
if [ $? -ne 0 ];then
	install_netmask
fi
cmd=$(which netmask)

# area to ASCII
ascarea=$DIR/ascarea.data
ASCAREA () {
	if [ ! -z $ascarea ];then
		rm -rf $ascarea
	fi
	# ip area
	ipareasrc=ctc
	ipareafile=ascctc.data
	awk -F'.' '{printf("%d%03d%03d%03d %s\n",$1,$2,$3,$4,$0)}' $ipareasrc | \
		sort -n | awk '{print $2}' \
		> $ipareafile

	for area in $(awk '{print $0}' $ipareafile);do
		range=$($cmd -r $area | awk '{print $1}')
		sta=$(echo $range | awk -F'-' '{print $1}')
		end=$(echo $range | awk -F'-' '{print $2}')
		ASCSTA=$[2#$($cmd -b $sta | awk -F'/' '{print $1}' | sed 's/ //g')]
		ASCEND=$[2#$($cmd -b $end | awk -F'/' '{print $1}' | sed 's/ //g')]

		lastnum=$[$(tail -n 1 $ascarea.nonu | awk '{print $NF}')+1] &>/dev/null
		if [ $lastnum -eq $ASCSTA ];then
			sed -i "\$s/ [0-9]*$/ $ASCEND/" $ascarea.nonu
			else
			echo $ASCSTA $ASCEND >> $ascarea.nonu
		fi
	done
	cat -n $ascarea.nonu | sed 's/\( *\)\([0-9].*\)/\2/;s/\t/ /' > $ascarea && rm -rf $ascarea.nonu
}

# get ip
ipaddfile=$dodir/allips.data
sortip=$dodir/sortip.data
get_ip () {
	logdir=/ROOT/log/nginx/Rotate_logs
	if [ ! -z $ipaddfile ];then
		rm -rf $ipaddfile
	fi
	for ((i=7;i>=1;i--));do
		logdate=$(date -d "-$i days" "+%Y%m%d")
		logfile="$logdir/*com_access.log-$logdate.gz"
		for des in $(ls $logfile | egrep '(\/www|\/store)');do
			ipaddsrc=$des
			zcat $ipaddsrc | awk '{print $1}' \
				>> $ipaddfile
		done
	done

	# sort all ips
	if [ ! -z $sortip ];then
		rm -rf $sortip
	fi
	awk -F'.' '{printf("%d%03d%03d%03d %s\n",$1,$2,$3,$4,$0)}' $ipaddfile | \
		sort -n | awk '{print $2}' | uniq -c \
		> $sortip
}

# ip to ASCII
ascip=$dodir/ascip.data
ASCIP () {
	if [ ! -z $ascip ];then
		rm -rf $ascip
	fi
	while read cou ip;do
		ASCIP=$[2#$($cmd -b $ip | awk -F'/' '{print $1}' | sed 's/ //g')]
		echo $ASCIP $cou >> $ascip
	done < $sortip
}

pvcount=0;uvcount=0
total () {
	cp $ascarea $ascarea.doit
	while read ip cou;do
		while read num sta end;do
			if [ $ip -lt $sta ];then
				modify=0
				break
			fi
		echo $ip $cou $num $sta $end $count
			if [ $ip -ge $sta -a $ip -le $end ];then
				pvcount=$[$pvcount+$cou]
				uvcount=$[$uvcount+1]
				modify=0
				break
			fi
			if [ $ip -gt $end ];then
				modify=1
				break
			fi
		done < $ascarea.doit
		if [ $modify -eq 1 ];then
			sed -i '1d' $ascarea.doit
		fi
		if [ ! -s $ascarea.doit ];then
			break
		fi
	done < $ascip
	pvtotal=$(cat $ipaddfile|wc -l)
	uvtotal=$(cat $ascip|wc -l)
	echo -e "pv: $pvcount/$pvtotal\nuv: $uvcount/$uvtotal" > resault.wwwstore
}

#-------doit------#

###################################
#ASCAREA
###################################

get_ip
ASCIP
total
