#!/usr/bin/perl

use strict;
use warnings;

use CGI qw(header request_method Vars);
use JSON;

# File to save data to
use constant FILE_JSON => "metar-log.json";

# Subroutine to read complete text of a file - returns undefined on errors
sub file_read($) {
	my $file = shift();
	if (open(my $fh, "<", $file)) {
		my $data = do {
			local $/ = undef;	
			<$fh>;
		};
		return $data;
	} else {
		warn("Cannot open file '$file': $!");
		return;
	}
}

# Subroutine to write to a file
sub file_write($$) {
	my ($file, $data) = @_;
	if (open(my $fh, ">", $file)) {
		print $fh $data;
		close($fh);
		return 1;
	} else {
		warn "Cannot write to file '$file': $!";
		return 0;
	}
}

my $cgi = new CGI; 

print($cgi->header());

if (defined(request_method()) and request_method() eq "POST") {
	my @values;
	{ # Localise JSON text
		my $json_text = file_read(FILE_JSON);
		if (!defined($json_text)) { # On file read error
			die("Failed to read file '" . FILE_JSON . "'!");
		}
		# Populate array with values from JSON
		@values = @{decode_json($json_text)->{"values"}};
	}
	my $time_stamp = time();
	my %hash_values = (
			"time_stamp" => $time_stamp,
			"station" => scalar($cgi->param("text_station")),
			"time" => scalar($cgi->param("text_time")),
			"wind" => scalar($cgi->param("text_wind")),
			"visibility" => scalar($cgi->param("text_visibility")),
			"clouding" => scalar($cgi->param("text_clouding")),
			"temperatures" => scalar($cgi->param("text_temperatures")),
			"qnh" => scalar($cgi->param("text_qnh")),
			"significant_weather" => scalar($cgi->param("text_significant_weather")),
			"remarks" => scalar($cgi->param("text_remarks"))
	);
	push(@values, \%hash_values);
	if(file_write(FILE_JSON, encode_json({"values" => \@values}))) {
		print("Data logged:<br /><pre>"
				. "\nTime stamp:\t$time_stamp"
				. "\nStation:\t" . $cgi->param("text_stations")
				. "\nTime:\t" . $cgi->param("text_time")
				. "\nWind:\t" . $cgi->param("text_wind")
				. "\nVisibility:\t" . $cgi->param("text_visibility")
				. "\nClouding:\t" . $cgi->param("text_clouding")
				. "\nTemperatures:\t" . $cgi->param("text_temperatures")
				. "\nQNH:\t" . $cgi->param("text_qnh")
				. "\nAny significant weather:\t" . $cgi->param("text_significant_weather")
				. "\nRemarks:\t" . $cgi->param("text_remarks") . "</pre><hr />");
	} else {
		print("Failed to write to file '" . FILE_JSON . "'!");
	}
} else {
	print("Only POST requests allowed!");
}

__END__
JSON:
{
	"values": [
		{"epoch": 1234567890, "station": "VAAH", "time": "012345", "wind": "18003KT",
			"visibility": "5000 HAZE", "clouding": "SCT020 SCT100",
			"temperatures": "30/20", "qnh": "Q1011", "significant_weather": "",
			"remarks": ""} 
	]
}
