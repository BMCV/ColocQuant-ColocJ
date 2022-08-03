#use strict;
#use warnings;

#this program converts the given trajectories into a format that is compatible with MTrackJ

my $num_args = $#ARGV + 1;
if ($num_args!=2){
	print "Usage: perl convertTracksToMTrackJFormat.pl <input_dir> <output_dir>\n";
	exit;
}


#print STDOUT "DIR: ";
$dir1 = shift;
$outDir = shift;



if (-d "$outDir"){

}
else {
	mkdir("$outDir", 0755) || die "Cannot mkdir newdir: $!";
}


opendir(DIR1, $dir1);
@dir1_filesA = readdir(DIR1);
closedir (DIR1);

$c = 0;
foreach $entry (@dir1_filesA) {	
  	next if (-d "$dir1/$entry"); 
	if ($entry ne "." || $entry ne ".."){
		$dir1_files[$c] = $entry;
		$c = $c + 1;
	}
}

$i = 1;
$oldX = -1;
$oldY = -1;
$sep_char = " ";

#one file for all trajectories
open(OUTFILE,">$outDir/tracks.mdf") or die "Unable to open file!";
#print "$outDir/tracks.mdf \n";
#print header
print OUTFILE "MTrackJ 1.3.0 Data File \n";
print OUTFILE "Assembly 1\n";
print OUTFILE "Cluster 1\n";

foreach $entry (@dir1_files) {
	
  	next if (-d "$dir1/$entry"); 
  	#print $entry . "\n";
	#read first line
	#print "$i"."\n";
	#print "$dir1/$dir1_files[$i]"."\n";
	if ("$dir1_files[$i]" ne "." && "$dir1_files[$i]" ne ".."){
		print "$dir1/$entry"."\n";
		open(TEST,"$dir1/$entry") or die "Unable to open file!";
		
		$c = 0;
		$oldX = -1;
		$oldY = -1;
		$dist = 0;
		#print header
		$entry =~ s{\.[^.]+$}{};
		$entry =~ tr/0-9//cd;
		#print OUTFILE "Track $entry\n";
		print OUTFILE "Track $entry\n";
		#print "Track $entry\n";
		print "Track $entry\n";
		while($line1 = <TEST>){
			@contents1 = split(",",$line1);
			$t = $contents1[0];
			$x = $contents1[1];
			$y = $contents1[2];
			$adj_avg_intensity = $contents1[3];
			$pixel_count = $contents1[6];
			chop($dist = $contents1[3]);
	
			print OUTFILE "Point ", ($c+1), $sep_char, $x, $sep_char , $y, $sep_char, "1.0", $sep_char, ($t+1),  $sep_char, "1",  $sep_char, $adj_avg_intensity, $sep_char, $pixel_count,"\n";
			$c = $c+1;
		}
	
		close(TEST);
		#unlink("$dir1/$entry");
	
	}

	$i = $i+1;	

}
print OUTFILE "End of MTrackJ Data File \n";
	close(OUTFILE);	



