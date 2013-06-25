
use strict;
use Socket;
use MIME::Base64;
use Encode;
$|++;

my %h_head;

open(F,"file");
my $text;
while (<F>) {
	$text.=$_;
}

my @res = split ("\n\n", $text);
my $head = $res[0];

@res = split("\n", $head);

my @length = split (" ",$res[0],3);
my $length = $length[1];
for my $field (keys @res) {
	my @a = split(":", $res[$field], 2);
	$h_head{$a[0]} = $a[1];	
}

my $Subject = decode("MIME-Header", $h_head{'Subject'});


print "From : $h_head{'From'}\n";
print "To : $h_head{'To'}\n";
print "Date : $h_head{'Date'}\n";
print "Subject : $Subject\n";
print "Length : $length\n";

