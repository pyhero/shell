#!/bin/bash
#
# Author: Xu Panda
# Update: 2015-07-02

if [ $# -lt 1 ];then
	echo "Useage:$0 {storage name}"
	exit 2
fi
storage=$1
if [ -e $storage ];then
	echo "$storage allready exists."
	exit 2
fi

ROOT="/ROOT/svn"
if [ ! -d $ROOT ];then
	echo "$ROOT:No such file or directory!"
	exit 2
fi
cd $ROOT

svnadmin create $storage
chown -R apache.apache $storage
mkdir -p /ROOT/tmp/svn/{trunk,branches,tags}
svn import -m 'Initializing basic repository structure' /ROOT/tmp/svn/ http://svn.xupp.net/$storage/
