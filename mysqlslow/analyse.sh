#!/bin/bash
#

# Weekly analyse,so rotate log my miss some.
# Beat version,so use root.

ports=16888

dir=$(cd `dirname $0`;echo $PWD)
today=$(date "+%F")
analyse_dir=$dir/analyse/$today

mail () {
	cmd=$dir/sendEmail
	/usr/bin/printf "%b" "Mysql@$port<br><br>Total slow sql@last_week:$count<br><br>Top 10 as attachment.<br><br><br><br>http://report.aiuv.cc<br><br><br><br>" | \
		$cmd -f report@aiuv.cc \
			-t dev@aiuv.cc \
			-s smtp.qq.com \
			-u "Mysql Weekly Report" \
			-xu report@aiuv.cc \
			-xp Pa1991lftih \
			-o message-content-type=html \
			-a $top
}			

for port in $ports;do
	srclog_dir=/ROOT/log/mysql/$port
	srclog=$srclog_dir/slow.log

	dodir=$analyse_dir/$port && mkdir -p $dodir && cd $dodir
	analyse_log=$dodir/slow.log
	[ ! -f $analyse_log ] && mv $srclog $analyse_log

	/ROOT/bin/mysqladmin -S /ROOT/tmp/mysql-$port\.sock -uroot -pPpY3IWF1O83e flush-logs

	count=$(/bin/grep Query_time $analyse_log | wc -l) && echo $count > slow.count

	top=$dodir/top.sql

	/ROOT/bin/mysqldumpslow -s c -t 10 $analyse_log > $top

	mail
done

# push 

des=post.aiuv.cc
/usr/bin/rsync -az $analyse_dir $des::MYSQL
