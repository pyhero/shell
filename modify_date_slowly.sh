#!/bin/bash
#
# Author: Panda
# Update: 20160928
#
# For our NTP-Server faster than the global time.
# Sync 1s/1d
#

LOG_FILE="/tmp/syncDate.log"
modify_time () {
	[ -z $offset ] && offset="-1"
	[ ! -f $LOG_FILE ] && LOG_FILE="/tmp/syncDate.log"
	echo $(date '+%T') >> $LOG_FILE
	NEW_TIME=$(date "+%T" --date="$offset second")
	/bin/date -s $NEW_TIME > /dev/null
	echo $(date '+%T') >> $LOG_FILE
	echo "" >> $LOG_FILE
}

NUM=30
while true;do
	modify_time
	NUM=$[$NUM-1]
	[ $NUM -le 0 ] && break
	sleep 86400
done

echo "check route & ntp service" >> $LOG_FILE

cmd=./sendEmail
[ ! -x $cmd ] && exit 2

## need define variables:
##		title:mail title
##		body:mail body

title="!!! Time Sync OK !!!"
body="check route & ntp service"
/usr/bin/printf "%b" "$body" | \
	$cmd -f nagios.noc@staff.aiuv.com \
		-t xujianhua@staff.aiuv.com \
		-s smtp.staff.aiuv.com \
		-u "$title" \
		-xu nagios.noc@staff.aiuv.com \
		-xp Xa1991lftih \
		-o message-content-type=html \
		> /dev/null
