#!/usr/bin/perl
#use strict;
#use warnings;

# Declare the subroutines
sub trim($);
sub process;
sub save_line;

my $input = $ARGV[0];
my $logFrame ;
my $output;

# This script parses eprime_flt.txt file and generates a summar .csv file
if( not $input or not -e $input){
	print STDERR "Usage: eprime2csv <eprime txt file> [frame] [output csv prefix] \n";
	print STDERR "  Converts E-Prime txt experiment file to tabular CSV file\n";
	print STDERR "  <eprime txt file> - an experiment text file generated by E-Prime\n";
	print STDERR "  [frame] - optionally output only a given log frame\n";
	print STDERR "  [output csv prefix] - output csv file prefix, if not given\n";
	print STDERR "  writes output to the same location as input text file.\n";
	exit 1;
}


# if 2nd parameter is a digit
if($ARGV[1]){
	if($ARGV[1] =~ /[0-9]/){
		$logFrame=$ARGV[1];
		if($ARGV[2]){
			$output=$ARGV[2];
		}else{
			# output to stdout	
		}
	}else{
		$output=$ARGV[1];
	}
}else{
	# figure out output
	$output = $input;
	$output =~ s{\.[^.]+$}{};
}



my ($line, $block, %map, $level, $key, $val,$columns,$data);
my @out_files;

# make sure that input has the correct encoding
system("file --mime \"$input\" | grep -q utf-16");
if(($? >> 8) == 0){
	system("iconv -f utf-16 -t utf-8 \"$input\" > tmp.txt");
	system("mv tmp.txt \"$input\"");
}


# process input file 
open (FILE, $input);
while (<FILE>) {
	chomp;
	# identify 	
	$line = $_;
	if($line =~ /\*\*\* (.*) Start \*\*\*/){
		$block = $1;
		%map = ($block,$level);		
	}elsif($line =~ /\*\*\* (.*) End \*\*\*/){
		$block = '';
		#process which log frame
		if($logFrame){		
			if($map{'LogFrame'} == $logFrame){		
				process(%map);
			}
		}else{
			process(%map);
		}
	}elsif($block){
		($key,$val) = split(":",$line);
		$map{trim($key)} = trim($val);		
	}elsif($line =~ /s*Level: (\d+)\s*/){
		$level = $1;
	}
}
close (FILE);


# NOW lets print the content of the file
foreach $frame (sort keys %columns){
	# print header of output
	my $header="";
	
	# print out the first row (header
	foreach $key (sort keys %{$columns{$frame}}){	
		if(not $header){
    		$header = "$key";
    	}else{
    		$header = "$header,$key";
    	}
	}
	save_line($frame,$header);
	
	# print out the rest of the data
	foreach $row ( @{$data{$frame}}) {
		my $line="";
		my $first = 1;
		foreach $key (sort keys %{$columns{$frame}}){
			$val = $row->{$key};
		
			if($first){
		   		$line = "$val";
	    	}else{
	    		$line = "$line,$val";
	    	}
	    	$first = 0;	
		}
		save_line($frame,$line);
	}
}


# close output files
for(my $i=0;$i< scalar(@out_files);$i++){
	if($out_file[$i]){
		close($out_file[$i]);	
	}
}
exit;

# save line of a given file
sub save_line {
	my $i = shift;
	my $line = shift;
	
	#open file if not already there
	if(not $out_files[$i]){
		if($output){	
			local *F1;		
			open (F1,">$output.$i.csv");
			$out_files[$i] = *F1;
		}else{
			$out_files[$i] = *STDOUT;
		}
	}
	my $f = $out_files[$i];
	print $f "$line\n";
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($){
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# process entry of interest in the file
sub process(){
	my $frame=$map{'LogFrame'};
	
	# fill out columns
	foreach $key (keys %map){	
		$columns{$frame}{$key} = 1;
	}
		
	# create new row
	my $row = {};
	
	# if not there add array down there
	if(not exists $data{$frame}){
		my @content = ();
		$data{$frame} = [@content];
	}
	
	foreach $key (keys %map){	
		$val = $map{$key};
		$row->{$key} = $val;
	}
	push @{$data{$frame}},$row;
}
		

