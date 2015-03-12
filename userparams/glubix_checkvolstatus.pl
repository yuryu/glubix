#!/usr/bin/perl
# Ex.
#       ./glubix_checkvolstatus.pl --volume_name vol0
#       ./glubix_checkvolstatus.pl --volume_name vol1 --volume_numbricks 4
#
# options:
#       --volume_name vol1
#       --volume_numbricks 4

use strict;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

my $rc = 0;
my $gluster_volume_name;
my $gluster_volume_numbricks;

my $getopt_result = GetOptions('volume_name=s' => \$gluster_volume_name,
                               'volume_numbricks=i', => \$gluster_volume_numbricks);

if ($gluster_volume_name eq "") {
	$rc = 0;
	printf "$rc\n";
	exit;
}

my $gluster_cmd = "/usr/sbin/gluster";
my $exec_cmd = "$gluster_cmd volume info $gluster_volume_name 2> /dev/null";

my $result = `$exec_cmd`;

if ($result =~ m/Status: Started/) {
	# volume status is Started
	$rc = 1;
	# Now parse the result of gluster volume status command
	# Sample output:
	# # gluster volume status test-volume
	# Status of volume: test-volume
	# Gluster process                        Port    Online   Pid
	# ------------------------------------------------------------
	# Brick arch:/export/rep1                24010   Y       18474
	# Brick arch:/export/rep2                24011   Y       18479
	# NFS Server on localhost                38467   Y       18486
	# Self-heal Daemon on localhost          N/A     Y       18491

	if ($gluster_volume_numbricks ne "" && $gluster_volume_numbricks > 0) {
		my $exec_cmd2 = "$gluster_cmd volume status $gluster_volume_name 2> /dev/null | grep '^Brick'";
		my $result2 = `$exec_cmd2`;
		my $online_bricks = 0;
		for ( split /^/, $result2 ) {
			my @stat = split;
			if ( $stat[-2] != 'Y' ) {
				last;
			}
			$online_bricks++;
		}
		$rc = ($online_bricks == $gluster_volume_numbricks) ? 1 : 0;
	}
} elsif ($result =~ m/Status: Stopped/) {
	# volume status is Stopped
	$rc = 0;
} else {
	# volume status is maintainance down or other
	$rc = 0;
}

printf "$rc\n";
exit
