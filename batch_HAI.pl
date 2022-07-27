#!/usr/bin/perl

use File::Basename;

use strict;
use warnings;

# --------------------------------------------------------------------------- #

# File:                 batch.pl
# Date created:         26 February 2021
# Date last modified:   27 July 2022
# Author:               Eliot Stanton (eliot.stanton@state.mn.us)
# Description:          Create list of data analysis deliverables from
#                       processed sequencing files and submit jobs to Slurm.

# --------------------------------------------------------------------------- #

# Define help string to be printed to command-line:
my $var_help    = "batch_HAI.pl [DIRECTORY_IN] [DIRECTORY_OUT] [EMAIL]

Batch submits the pairs of fastq files formatted YYYYEL-#####_R1.fastq.gz
[DIRECTORY IN] Directory containing pairs of FASTQ files for processing
[DIRECTORY OUT] Directory to contain output subdirectories
[EMAIL] Email address for notification (optional)
 ";

# --------------------------------------------------------------------------- #

# Variables passed to this script:
my $dir_in              = $ARGV[0];
my $dir_out             = $ARGV[1];
#my $var_upload		= $ARGV[2];
my $var_email		= $ARGV[2] || "";

# Print $var_help and end script if incorrect number of arguments:
die "$var_help\n" unless scalar @ARGV == 2 || scalar @ARGV == 3;

# Print $var_help and end script if $dir_in is missing:
die "$var_help \nNo input directory found!\n" unless -d $dir_in;

# Ensure $dir_in is accessible for other users:
system ( "chmod 770 $dir_in" );

# Make initial output directory if it doesn't already exist:
unless ( -d $dir_out ) {

	system ( "mkdir $dir_out" );
	system ( "chmod 770 $dir_out" );

}

# Data structures used in this script:
my @array_in;
my @array_out;

# Variables used by this script:
my $var_submit          = dirname(__FILE__);

# Add complete path for slurm submission script:
$var_submit             = `realpath $var_submit`;
chomp $var_submit;

# Add filepaths for submission slurm scripts:
my $var_submit_sh       = "$var_submit\/submit_HAI.sh";
#my $var_analysis_sh	= "$var_submit\/analysis.sh";

# --------------------------------------------------------------------------- #

# Create a list of samples to be processed by importing the contents of
# $dir_in to %hash_in:
opendir my $dir_read, "$dir_in" or die "Cannot open directory $dir_in!";

# Import contents of $dir_read into @array_fastq:
@array_in = readdir $dir_read;

# Close $dir_read;
closedir $dir_read;

# Remove . and .. from @array_in:
splice @array_in, 0, 2;

# Print $var_help and end script if $dir_in is empty:
die "$var_help \nPaired fastq files required in $dir_in!\n" unless scalar @array_in > 1;

# --------------------------------------------------------------------------- #

# Sort @array_in:
@array_in	= sort { $a cmp $b } @array_in;

# Iterate through samples in @array_in and condense to sample name:
for ( my $i = 0; $i < scalar @array_in; $i+=2 ) {

        # Define file name:
        my $file_in     = $array_in[$i];

        # Grab just the ID number:
        my $var_sample  = ( split ( /\_/, $file_in ))[0];

        # Store ID number in @array_out:
        push @array_out, $var_sample;

}

# --------------------------------------------------------------------------- #

# Iterate through @array_out submitting files to be processed:
for ( my $i = 0; $i < scalar @array_out; $i++ ) {

        my $var_ID      = $array_out[$i];

	# TODO: Make final output directory if it doesn't exist:
	system ( "mkdir $dir_out/$var_ID" ) unless -d "$dir_out/$var_ID";

        print "\n$i: $var_ID:\n";

	print "\tsbatch \\
		-p msismall \\
		--output=$dir_out/$var_ID/$var_ID\-slurm.out \\
		$var_submit_sh \\
		$dir_in \\
		$var_ID \\
		$dir_out\n";

	system ("sbatch --mail-type=END --mail-type=FAIL --mail-user=$var_email -p msismall --output=$dir_out/$var_ID/$var_ID\-slurm.out $var_submit_sh $dir_in $var_ID $dir_out");

	sleep 1;

#	last if $i >=400;

}
