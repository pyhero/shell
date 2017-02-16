#!/bin/bash
#
# Author: Xu Panda
# Update: 2015-07-02

domain="svn.xupp.net"
authname="Panda Auth"
dn="dc=xupp,dc=net"
ldap="$url/$dn"
url="ldap://ldap.xupp.net"
if ! grep 'ldap.xupp.net' /etc/hosts > /dev/null;then
	echo '127.0.0.1 ldap.xupp.net' >> /etc/hosts
fi

dir=$(cd `dirname $0`;echo $PWD)
## apache
yum install httpd -y > /dev/null
chkconfig httpd on

## subversion
yum install subversion mod_dav_svn mod_authz_ldap -y > /dev/null

ROOT="/ROOT/svn"
mkdir -p $ROOT;chmod o-rwx $ROOT

storage=/ROOT/svn/noc
rm -rf $storage;svnadmin create $storage
chown -R apache.apache $storage

## svn whith apache
conf=/etc/httpd/conf.d/subversion.conf
if [ ! -f $conf ];then
	echo -e "$conf:No such file or directory.\n\e[31mYou may not access svn with http!\e[0m"
	sleep 1
cat > $conf << EOF
LoadModule dav_svn_module     modules/mod_dav_svn.so
LoadModule authz_svn_module   modules/mod_authz_svn.so
EOF
fi

chmod o-rwx $conf
sed -i '/^#/d;/^$/d' $conf
cat >> $conf << EOF

<VirtualHost *:80>
	ServerName $domain
	DocumentRoot $ROOT
	<Location />
		SVNParentPath $ROOT
		DAV svn
		AuthType Basic
		AuthName '$authname'
		AuthBasicProvider ldap
		AuthLDAPUrl "$ldap?uid??(|(allowsvn=1)(memberOf=svn))"
		AuthLDAPBindDN "cn=auth,ou=Auth,$dn"
		AuthLDAPBindPassword AMSSR5xg8
		Require valid-user
	</Location>
</VirtualHost>
EOF

/etc/init.d/httpd restart > /dev/null

if ! grep 'svn.xupp.net' /etc/hosts > /dev/null;then
	echo '127.0.0.1 svn.xupp.net' >> /etc/hosts
fi
mkdir -p /ROOT/tmp/svn/{trunk,branches,tags}
svn import -m 'Initializing basic repository structure' /ROOT/tmp/svn/ http://svn.xupp.net/noc/
