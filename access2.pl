#!/usr/bin/perl


use strict;

system "scp scpuser\@192.168.0.5:/online/control/access/access_fiz.csv /online/access/access_fiz.csv > /dev/null 2>&1";
system "scp scpuser\@192.168.0.5:/online/control/access/access_ur.csv /online/access/access_ur.csv > /dev/null 2>&1";
system "scp scpuser\@192.168.0.5:/online/control/access/iptv.conf /online/access/iptv.conf > /dev/null 2>&1";


#system "scp scpuser\@192.168.0.5:/online/control/access/access_fiz.csv /online/access/access_fiz.csv";
#system "scp scpuser\@192.168.0.5:/online/control/access/access_ur.csv /online/access/access_ur.csv";
#system "scp scpuser\@192.168.0.5:/online/control/access/iptv.conf /online/access/iptv.conf";

#system "/usr/bin/perl /online/temp.pl access > /online/access/access_fiz.csv";

my $fiz_file="/online/access/access_fiz.csv";
my $ur_file="/online/access/access_ur.csv";
my $tv_file="/online/access/iptv.conf";

my $allow_table="table 1";

my ($count_add_fiz,$count_del_fiz)=action(parse_ipfw(),parse_file());

sub parse_ipfw{
    my $access_table=shift;
    my @table=`/sbin/ipfw $allow_table list | /usr/bin/awk '{print \$1}'`;
    chomp @table;
    my %ipfw_table=map { $_ => 1 } @table;
    return \%ipfw_table;
}

sub parse_file{
    my %ip_conf=();
    open F,"<$fiz_file";
    my @f=<F>;
    chomp @f;
    %ip_conf=(%ip_conf, map { $_ => 1 } @f);
    close F;
    open F,"<$ur_file";
    @f=<F>;
    chomp @f;
    %ip_conf=(%ip_conf, map { $_ => 1 } @f);
    close F;
#    open F,"<$tv_file";
#    @f=<F>;
#    chomp @f;
#    %ip_conf=(%ip_conf, map { $_ => 1 } @f);

    $ip_conf{"89.105.144.35/32"}=1;
    $ip_conf{"89.105.158.150/32"}=1;
    $ip_conf{"172.31.240.4/32"}=1;
    $ip_conf{"37.200.67.147/32"}=1;
    $ip_conf{"192.168.0.0/24"}=1;
    $ip_conf{"127.0.0.0/8"}=1;
    $ip_conf{"89.105.158.0/24"}=1;
    $ip_conf{"224.0.0.0/24"}=1;
    $ip_conf{"169.254.0.0/16"}=1;
    $ip_conf{"95.170.190.0/24"}=1;
    $ip_conf{"185.26.216.0/24"}=1;
    $ip_conf{"195.225.38.70/32"}=1;
    $ip_conf{"89.105.146.0/24"}=1;
    $ip_conf{"89.105.144.100/32"}=1;

    my $ips=getif();
    foreach(@$ips){
	$ip_conf{"$_/32"}=1;
    }
    return \%ip_conf;
}

sub getif{
    my @ips=`ifconfig | grep "inet " | awk '{print \$2}'`;
    chomp @ips;
    return \@ips;
}

sub action{
    my ($ipfw_table,$ip_conf,$access_table)=@_;
    my $count_del=0;
    foreach my $item(keys %$ipfw_table){
#	print $item." ipfw\n" if $item =~/172.21.213.3/;
	unless(exists $$ip_conf{"$item"}){
	    system "/sbin/ipfw $allow_table del $item > /dev/null 2>&1";
	    print "del $item\n";
	    $count_del++;
	}
    }
    my $count_add=0;
    foreach my $itemm(keys %$ip_conf){
#	print $itemm." bill\n" if $itemm =~/172.21.213.3/;
	if(index($itemm,"0.0.0.0") == -1){
	    unless(exists $$ipfw_table{"$itemm"}){
		system "/sbin/ipfw $allow_table add $itemm > /dev/null 2>&1";
		print "add $itemm\n";
		$count_add++;
	    }
	}
    }
    return ($count_add,$count_del);
}

print "Total add/delete: $count_add_fiz/$count_del_fiz\n";
