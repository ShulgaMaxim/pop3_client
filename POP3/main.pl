#!/usu/bin/perl

use strict;
use Socket;
use MIME::Base64;
use Encode;

socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));

my $host = shift;
my $user_name = shift;
my $pass = shift;
my $port = 110; 
my $iaddr = inet_aton($host);   
my $paddr = sockaddr_in($port, $iaddr);

connect(SOCK, $paddr);
my $data = <SOCK>;
if ((substr $data,0,3) eq "+OK") {
	send (SOCK, "USER $user_name\n", 0);
	$data = <SOCK>;	
	if (($data =~ /(^\+OK)/)) {
		send (SOCK, "PASS $pass\n", 0);
		$data = <SOCK>;
		if (($data =~ /(^\+OK)/)) {
			print "Welcome!\n"
		} else {
			print "Bad user_name or pass\n";
			exit(1);
		}
	}
} else {
	print "Bad host\n";
	exit(1);
}

my $length;
send (SOCK, "STAT\n", 0);
$data = <SOCK>;
if (($data =~ /(^\+OK)/)) {
	my @data = split (" ", $data, 3);
	$length = $data[1];
	print $length;
} else {
	print "Bad STAT request\n";
}

if ($length) {
	for (my $i = 1; $i <= $length; $i++) {
		send (SOCK, "LIST $i\n", 0);
		my $data = <SOCK>;
		my @len = split " ", $data, 3;
		my $len = $len[2];
		send (SOCK, "TOP $i 0\n", 0);
		my $text;
		while (<SOCK>) {
			last if ($_ =~ /(^\.)/);
			$text .= $_;
		}
		
		if (($text =~ /(^\+OK)/)) {
			print "\n\nMessage №$i\n";
			&parser($text, $len);
		} else {
			print ((substr $text,0,3)."\n");
			print "Bad \"RETR $i\" request\n"; 
		}
	}
}

close(SOCK);
print "$host $user_name $pass \n";


sub parser {

	my $text = shift;
	my $len = shift;
	
	my %h_head;

	my @res = split ("\n\n", $text);
	my $head = $res[0];

	@res = split("\n", $head);

	for my $field (keys @res) {
		my @a = split(":", $res[$field], 2);
		$h_head{$a[0]} = $a[1];	
	}
	

	my @from = split (" ", $h_head{'From'}, 2);
	$from[0] = decode("MIME-Header", $from[0]);
	my $Subject = decode("MIME-Header", $h_head{'Subject'});
	my $count = scalar (@from);

	print "From : @from\n";
	print "To : $h_head{'To'}\n";
	print "Date : $h_head{'Date'}\n";
	print "Subject : $Subject\n";
	print "Length : $len\n";
}