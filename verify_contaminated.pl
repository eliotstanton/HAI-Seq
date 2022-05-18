#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Getopt::Std;

# --------------------------------------------------------------------------- #

# File:         verify_contaminated.pl
# Date created: 02 February, 2022
# Author:       Eliot Stanton (eliot.stanton@state.mn.us)
# Description:  Create synthetic contaminated files.

# --------------------------------------------------------------------------- #

# Define variables used in this script:
my $var_partition       = "small";
my $var_threads         = 12;
my $var_proportion      = 50;
my $dir_downloads	= "downloads";
my $dir_contaminated	= "contaminated";

# Define location of this script:
my $var_path            = dirname(__FILE__);
$var_path               = `realpath $var_path`;
chomp $var_path;

my %hash_opts;
getopts('l:h', \%hash_opts);

# Create array holding SRR accessions:
my @array_SRR = ( "SRR14083920",
"SRR14790820",
"SRR16292061",
"SRR14083921",
"SRR14083945",
"SRR14083891",
"SRR15066362" );

my $var_SRR     = join( "\n    - ", @array_SRR);

my $var_help    = "\nverify_contaminated.pl -l [SRR LIST]\n
 Files used for creating synthetic contaminated FASTQ files are looked for
 in directory $dir_downloads. Synthetic contaminated files are stored in
 directory $dir_contaminated.

 -l SRR LIST: Optional text file containing list of SRA accessions to be used.
 If no text file is specified the default list will be used. Run the program
 verify_download.pl to download files.
 The default list of accessions used is: \n    - $var_SRR\n";

if ( $hash_opts{h} ) {

        print "$var_help\n";

        exit;

}

if ( $hash_opts{l} ) {

        my $file_in     = $hash_opts{l};

        print "$var_help ERROR: File $file_in not found!\n" and exit unless -e $file_in;

        print "$file_in\n";

        # Import text file and store entries in @array_SRA:
        @array_SRR      = @{ file_to_array ( $file_in ) };
        $var_SRR        = join ( "\n    - ", @array_SRR);

        # Print information to command-line:
        print "SRA accessions imported from $file_in:\n    - $var_SRR\n\n\n";

}

exit;

# --------------------------------------------------------------------------- #

# Create directory to hold synthetic contaminated reads:
mkdir "$dir_contaminated" unless -f $dir_contaminated;

# Iterate through @array_SRR and create synthetic FASTQ files:
for ( my $i = 0; $i < scalar@array_SRR; $i++ ) {

	my $var_SRR1     = $array_SRR[$i];

	print "$i: $var_SRR1\n";

	for ( my $j = $i + 1; $j < scalar @array_SRR; $j++ ) {

		my $var_SRR2	= $array_SRR[$j];

		print "\t$j: $var_SRR2\n";

		my $var_contaminated_sh	= "$var_path/contaminated.sh";

		system ( "sbatch -p $var_partition --cpus-per-task=$var_threads $var_contaminated_sh $var_SRR1 $var_SRR2 $var_threads $var_proportion $dir_downloads $dir_contaminated" );

#		last if $i > 1;

	}

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
