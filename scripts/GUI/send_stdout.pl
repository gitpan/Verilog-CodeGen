#!/usr/bin/perl -w
use strict;
use IO::Socket;
my $new_sock;
my $buff;

my $sock = new IO::Socket::INET (
PeerAddr => 'localhost',
				 PeerPort => 2507,
				 Proto => 'tcp',
				 );
die "Socket could not be created: $!" unless $sock; 
while (<STDIN>) {
my $line=$_;
print $sock $line;
#print "SENT:$line\n";
$sock->flush();
}
close ($sock);



