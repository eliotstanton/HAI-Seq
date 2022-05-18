#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Getopt::Std;

# --------------------------------------------------------------------------- #

# File:			verify_download.pl
# Date created:		02 February, 2022
# Date modified:	24 March, 2022
# Author:		Eliot Stanton (eliot.stanton@state.mn.us)
# Description:		Coordinates downloading FASTQ files from SRA for 
#			verifying HAI_QC pipeline.

# --------------------------------------------------------------------------- #

# Define variables used in this script:
my $var_partition	= "small";
my $var_threads		= 4;
my $dir_downloads	= "downloads";
my $dir_downsampled	= "downsampled";
my $dir_contaminated	= "contaminated";

# Define location of this script:
my $var_path		= dirname(__FILE__);
$var_path		= `realpath $var_path`;
chomp $var_path;

my %hash_opts;

getopts('l:p:h', \%hash_opts);

my $var_proportion	= $hash_opts{p};
$var_proportion		= "30" unless $var_proportion;

# Create array holding SRR accessions:
my @array_SRR	= ( "SRR14083920",
"SRR14790820",
"SRR16292061",
"SRR14083921",
"SRR14083945",
"SRR14083891",
"SRR15066362",
"SRR14083911",
"SRR14790815",
"SRR14084007",
"SRR14581016",
"SRR14083944",
"SRR16983636",
"SRR15065939",
"SRR14790813",
"SRR14790818",
"SRR16292058",
"SRR14083979",
"SRR14083935",
"SRR14083890",
"SRR15065885" );

my $var_SRR	= join( "\n    - ", @array_SRR);

my $var_help    = "\nverify_download.pl -p [SUBSAMPLE PROPORTION] -l [SRR LIST]\n
 This program downloads FASTQ files from the SRA database using a list of SRR 
 accessions and subsamples those files. Files downloaded from SRA are stored 
 in directory $dir_downloads. Subsampled files are stored in directory $dir_downsampled.

 -p subsample proportion expressed as percentage (optional default: 30)
 -l text file containing list of SRA accessions to be downloaded (optional)
 If no text file is specified the default list will be used.
 The default list of accessions downloaded is:\n    - $var_SRR\n\n";

if ( $hash_opts{h} ) {

	print "$var_help\n";

	exit;

}

if ( $hash_opts{l} ) {

	my $file_in	= $hash_opts{l};

	print "$var_help ERROR: File $file_in not found!\n" and exit unless -e $file_in;

	print "$file_in\n";

	# Import text file and store entries in @array_SRA:
	@array_SRR	= @{ file_to_array ( $file_in ) };
	$var_SRR	= join ( "\n    - ", @array_SRR);

	# Print information to command-line:
	print "SRA accessions imported from $file_in:\n    - $var_SRR\n\n\n";

}

# --------------------------------------------------------------------------- #

# Create directory to hold reads:
mkdir "$dir_downloads" unless -d $dir_downloads;

# Create directory to hold downsampled reads:
mkdir "$dir_downsampled" unless -d $dir_downsampled;

# Create directory to hold synthetic contaminated reads:
mkdir "$dir_contaminated" unless -d $dir_contaminated;

# Iterate through @array_SRR and download each pair of FASTQ files:
for ( my $i = 0; $i < scalar@array_SRR; $i++ ) {

	my $var_SRR	= $array_SRR[$i];

	my $var_download_sh	= "$var_path/download.sh";

	print "$i: $var_SRR\n";

	system ( "sbatch -p $var_partition --cpus-per-task=$var_threads $var_path\/download.sh $var_SRR $var_threads $var_proportion $dir_downloads $dir_downsampled");

#	last if $i > 1;

}

# --------------------------------------------------------------------------- #

# Subroutine for reading a file into an array as strings:
sub file_to_array {

        # Arguments:
        my ( $file_in ) = @_;

        # Data structures:
        my @array_out;

        # Open $file_in:
        open ( my $file_read, '<', $file_in ) or die "Unable to open $file_in!";

        # Store each line of $file_in as a string in @array_out:
        while ( <$file_read> ){

                chomp $_;

                push @array_out, $_;

        }

        # Close $file_in:
        close ( $file_read );

	# Check and remove empty elements:
	for ( my $i = 0; $i < scalar @array_out; $i++ ) {

		unless ( $array_out[$i] ) {

			splice (@array_out, $i, 1);

			$i--;

		}

	}

        # Return reference to @array_out and end subroutine:
        return \@array_out;

}

# --------------------------------------------------------------------------- #

