# Apache2 MSAD Authentication Module for mod_perl2
# Derived from Reg Quinton's Apache2::AuthenMSAD (http://search.cpan.org/~reggers/Apache2-AuthenMSAD-0.02/AuthenMSAD.pm)
# $Id: AuthenMSAD.pm 49 2014-01-12 06:56:46Z kai.li $
package Apache2::AuthenMSAD;

use mod_perl2 ;
use Apache2::Access ;
use Apache2::Log ;
use Apache2::RequestRec ;
use Apache2::RequestUtil ;
use Apache2::Const -compile => qw(HTTP_UNAUTHORIZED HTTP_INTERNAL_SERVER_ERROR DECLINED HTTP_FORBIDDEN OK) ;
use Net::LDAP;
use Digest::MD5 qw(md5);
use Data::Dumper;
use strict;

$Apache2::AuthenMSAD::VERSION = '0.03';

sub in_array {
        my ($arr, $search_for) = @_;
        return grep {$search_for eq $_} @$arr;
}

sub get_groups_of_sam {
	my ($ldap, $basedn, $sam, $depth) = @_;
	my @groups = ();

	$depth-- > 0 || return ();

	my $mesg = $ldap->search(
		base => $basedn,
		filter => "(sAMAccountName=$sam)",
		attrs => ['memberOf'],
		);
	if (!$mesg || ($mesg && $mesg->count()<1)) {
		return ();
	}

        my @entries = $mesg->entries;
        my $values = $entries[0]->get_value("memberOf", asref=>1);
        foreach (@$values) {
                if(m/CN=([-\w]+),/i) {
			@groups = (@groups, lc $1,
				get_groups_of_sam($ldap, $basedn, $1, $depth));
		}
	}
	return (@groups);
}

sub cache_credential {
	my ($cred_file, $user, $domain, $pass, $user_groups) = @_;
	open C, ">$cred_file";
	printf C time . ":" . unpack 'H*', md5("$user\@$domain:$pass");
	printf C "\n@$user_groups";
	close C;
}

sub handler {
        my $r = shift;
        # Continue only if the first request.
        #  return OK unless $r->is_initial_req;

        # Grab the password, or return in HTTP_UNAUTHORIZED
        my ($res, $pass) = $r->get_basic_auth_pw;
        return $res if $res;

        my $user = lc $r->user;
        my $domain = $r->dir_config('MSADDomain') || "no-domain";

	if(-1 != index($user, '@')) {
		my @user_ary = split('@', $user);
		$user = $user_ary[0];
		$domain = $user_ary[1];
	}

	# for security
	if($user =~ /[^-.a-zA-Z0-9]/ || $domain =~ /[^-.a-zA-Z0-9]/) {
                $r->log_reason("user[$user\@$domain] - Bad character", $r->uri);
                return Apache2::Const::HTTP_UNAUTHORIZED;
	}

        if ($pass eq "") {
                $r->note_basic_auth_failure;
                $r->log_reason("user[$user\@$domain] - no password supplied", $r->uri);
                return Apache2::Const::HTTP_UNAUTHORIZED;
        }

        if ($user eq "") {
                $r->note_basic_auth_failure;
                $r->log_reason("user[$user\@$domain] - no userid supplied", $r->uri);
                return Apache2::Const::HTTP_UNAUTHORIZED;
        }

        my $server = $r->dir_config('MSADServer') || $domain;
        my $basedn = $r->dir_config('MSADBaseDN') || "";
        my @group_require = map { lc $_ } split /\s/, $r->dir_config('MSADGroup') || ();
        my @users_require = map { lc $_ } split /\s/, $r->dir_config('MSADUser') || ();

	# merge apache Require [user|group] with PerSetvar [MSADUser|MSADGroup]
	my %require =
		map { my ($k, $v) = split /\s+/, $_->{requirement}, 2; ($k, $v||'') }
		@{ $r->requires };
	@users_require = (@users_require, split /\s+/, lc @require{"user"});
	@group_require = (@group_require, split /\s+/, lc @require{"group"});

	$r->log->notice("user[$user\@$domain] users_require=@users_require, group_require=@group_require");

        # search cache credential for efficiency, keyn, 2008-9-2
        my $cred_dir = "/tmp/AuthenMSAD";
        my $cred_file = "$cred_dir/$user\@$domain";
        if(! -d $cred_dir) {
                mkdir $cred_dir;
        }
        if(-e $cred_file) {
                open C, "$cred_file";
                my @data = <C>;
                close(C);

		chomp $data[0];
		my ($last, $cred) = split ':', $data[0];
		if ( ((time-$last)<600) && ($cred eq unpack 'H*', md5("$user\@$domain:$pass")) ) {
        		if (in_array(\@users_require, $user)) {
				$r->log->notice("user[$user\@$domain][cached] users_require satisfied");
				return Apache2::Const::OK;
			} else {
				foreach (split / /, @data[1]) {
					if (in_array(\@group_require, lc $_)) {
						$r->log->notice("user[$user\@$domain][cached] group_require [$_] satisfied");
						return Apache2::Const::OK;
					}
				}	
			}
		}
        }

        my $ldap = Net::LDAP->new($server, version=>3);
        unless ($ldap) {
                $r->note_basic_auth_failure;
                $r->log_reason("user[$user\@$domain] - MSAD LDAP Connect Failed", $r->uri);
                return Apache2::Const::HTTP_UNAUTHORIZED;
        }

        my $result= $ldap->bind (dn => "$user\@$domain", password => $pass);
        if (!$result || ($result && $result->code)) {
                $r->note_basic_auth_failure;
                $r->log_reason("user[$user\@$domain] - Active Directory Authen Failed", $r->uri);
                return Apache2::Const::HTTP_UNAUTHORIZED;
        }

	my @user_groups;
        if(in_array(\@users_require, $user)) {
		# store credential, keyn, 2008-9-2
		$r->log->notice("user[$user\@$domain] caching credential for user satisfying");
		cache_credential($cred_file, $user, $domain, $pass, \@user_groups);

                return Apache2::Const::OK;
        }

	@user_groups = get_groups_of_sam($ldap, $basedn, $user, 3);
	$r->log->notice("user[$user\@$domain] user_groups=@user_groups");
	foreach (@user_groups) {
		if(in_array(\@group_require, lc $_)) {
			# store credential, keyn, 2008-9-2
			cache_credential($cred_file, $user, $domain, $pass, \@user_groups);
			$r->log->notice("user[$user\@$domain] caching credential for group[$_] satisfying");

			return Apache2::Const::OK;
		}
        }

        $r->note_basic_auth_failure;
        $r->log_reason("user[$user\@$domain] - Active Directory Authen Failed with all try", $r->uri);
        return Apache2::Const::HTTP_FORBIDDEN;

}


1;
__END__

=head1 NAME

Apache2::AuthenMSAD - Microsoft Active Directory authentication for Apache

=head1 SYNOPSIS

    <Directory /foo/bar>
    # Authentication Realm and Type (only Basic supported)

    AuthName "Microsoft Active Directory Authentication"
    AuthType Basic

    # Authentication  method/handler

    PerlAuthenHandler Apache2::AuthenMSAD

    # The Microsoft Active Directory Domain Name must be set
    # The Active Directory Server Name will default to the domain.
    # BaseDN set the base dn to search for user group

    PerlSetVar MSADDomain ads.foo.com
    PerlSetVar MSADServer dc.ads.foo.com
    PerlSetVar MSADBaseDN DC=ads,DC=foo,DC=com

    # Require lines can be any of the following -- any user, one of a list
    # require user or group
    # when use require group, "require valid-user" must exist

    require user joe mary tom

    require group group1
    require valid-user
    </Directory>

    These directives can also be used in a .htaccess file.

=head1 DESCRIPTION

This perl module is designed to work with mod_perl2 and Net::LDAP. It
will authenticate users in a Windows 2000 or later Microsoft Active
Directory -- hence the acronym MSAD. Configuration parameters give the
DNS name used for the cluster of Microsoft Domain Controllers and the
Microsoft Domain name used within the Active Directory.

This relies on a surprising feature first brought to our attention by
Yvan Rodrigues here at the University of Waterloo. You can
authenticate with a Distinguished Name like "reggers@ads.foo.com"
(ie. the userPrincipalName in the Active Directory) and you don't need
to resort to the X509 Distinguished Name. Most LDAP authentication
methods require a guest account where you can login to find the user's
Distinguished Name and then login again as that name. Active Directory
has this extra feature which makes life much simpler.

At our site the domain mentioned in the userPrincipalName is
"ads.uwaterloo.ca" -- that is also the name we use for our collection
of Domain Controllers. You might not implement that convention. If you
do the MSADServer parameter is optional -- it defaults to the
MSADDomain.This version is patched to use mod_per2 (>=2.0x) and apache2.
It was tested in an production environment to work perfectly.

=head1 BEWARE

This builds on the Net::LDAP interface and as such passes the userid
and password in the clear. We've not been able to get Net::LDAPS to
work with Microsoft Active Directory. If anyone else has we'd dearly
love to hear from them.

=head1 AUTHOR

Yvan Rodrigues <yrodrigu@uwaterloo.ca>
Reg Quinton <reggers@ist.uwaterloo.ca>
Franz Skale <franz.skale@cubit.at>
Keyn Li <9@kai.li>

=head1 COPYRIGHT

Copyright (c) 2005 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

