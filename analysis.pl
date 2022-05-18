#!/usr/bin/perl

use strict;
use warnings;

# --------------------------------------------------------------------------- #

# File:                 analysis.pl
# Date created:         16 March 2021
# Date last modified:   24 March 2021
# Author:               Eliot Stanton (eliot.stanton@state.mn.us)
# Description:          Pull genome deliverables from sequencing data pipeline.

# --------------------------------------------------------------------------- #

# Variables imported by this script:
my $var_accession       = $ARGV[0];
my $dir_in              = $ARGV[1];
my $dir_out		= $ARGV[2];

# Define filepaths used by this script:
# TODO: Fix using fastq for original FASTQ file
$dir_out		= "$dir_out\/$var_accession";
my $file_out		= "$dir_out\/$var_accession\_stats.txt";
my $file_quast		= "$dir_out\/quast/report.txt";
my $file_kraken 	= "$dir_out\/$var_accession\_kraken2_report.txt";
my $file_FASTQ1		= "$dir_out/$var_accession\_filtered_R1.fastq";
my $file_FASTQ2		= "$dir_in/$var_accession\_R1.fastq";

# Data structures used by script:
my @array_out;

# Define temporary array to hold data and store in @array_out:
my @array_temp  = ( "Accession", "Original reads", "Processed reads", "Dropped (%)", 
		"Assembled genome length", "GC (%)", "Contigs", "Genus",
		"Kraken2 genus alignment", "Species", "Kraken2 species alignment",
		"Avg genome length", "Genome ratio", "Coverage depth",
		"Date analysed" );

push @array_out, \@array_temp;

# Define variables used by script:
my $var_num_reads	= 0;
my $var_ori_reads	= 1;
my $var_dropped		= 0;
my $var_GC		= 0;
my $var_contigs		= 0;
my $var_length		= 0;
my $var_genus		= "unknown";
my $var_species		= "unknown";
my $var_align_genus	= 0;
my $var_align_species	= 0;
my $var_avg_length	= 0;
my $var_ratio		= 0;
my $var_coverage	= 0;
my $var_date		= `date +%F`;
chomp $var_date;

# --------------------------------------------------------------------------- #

# Import $file_kraken into @array_kraken:
my @array_kraken        = @{ file_to_array ( $file_kraken ) };

# Import $file_quast into @array_quast:
my @array_quast         = @{ file_to_array ( $file_quast ) };

# Identify putative species identification from Kraken2 report:
( $var_genus, $var_align_genus, $var_species, $var_align_species ) = Kraken2 ( \@array_kraken );

# --------------------------------------------------------------------------- #

# Determine number of original paired reads in $file_FASTQ2:
$var_ori_reads          = `echo \$\(zcat $file_FASTQ2 | wc \-l) \/4 \| bc`;
chomp $var_ori_reads;

# Define variable for URL used to download average genome length:
my $var_html		= "https\:\/\/www\.ncbi\.nlm\.nih\.gov\/genome\/\?term\=$var_genus\+$var_species";

# Download taxon webpage from NCBI website for average genome length:
system "wget --output-document $var_accession.html -q $var_html";

# Convert website to array:
my @array_html          = @{ file_to_array ( "$var_accession.html" ) };

# Scrape average length from @array_html:
$var_avg_length         = Scrape (\@array_html);

# Convert length from Mbp to bp:
$var_avg_length         *= 1000000;

# Cleanup and remove the HTML file:
system ( "rm $var_accession.html" );

# --------------------------------------------------------------------------- #

# Iterate through @array_quast and find sum total assembly length, contig 
# number, GC content, read number, and read depth: 
for ( my $j = 0; $j < scalar @array_quast; $j++ ) {

	my @array_temp  = split (/\s/, $array_quast[$j]);

	if ( $array_quast[$j] =~ /Total length \(\>\= 0 bp\) /) {

		$var_length     = $array_temp[10];

	}

	if ( $array_quast[$j] =~ /\# contigs  / ) {

		$var_contigs    = $array_temp[20];

	}

	if ( $array_quast[$j] =~ /GC \(%\)/ ) {

		$var_GC = $array_temp[23];

	}

	if ( $array_quast[$j] =~ /\# left/ ) {

		$var_num_reads = $array_temp[23];

	}

	if ( $array_quast[$j] =~ /Avg\. coverage depth/ ) {

		$var_coverage	= $array_temp[11];

	} 

}

# Calculate dropped read percentage:
$var_dropped	= ( 1 - $var_num_reads/$var_ori_reads ) * 100;

# Round dropped read percentage to two decimals:
$var_dropped      = sprintf( "%.2f", $var_dropped );

# Determine genome ratio:
$var_ratio      = $var_length/($var_avg_length) unless $var_avg_length == 0;

# Round genome ratio to two decimals:
$var_ratio      = sprintf( "%.2f", $var_ratio );

# Store data in a temporary array and push to @array_out:
my @array_temp2		= ($var_accession, $var_ori_reads, $var_num_reads,
			$var_dropped, $var_length, $var_GC, $var_contigs, 
			$var_genus, $var_align_genus, $var_species,
			$var_align_species, $var_avg_length,
			$var_ratio, $var_coverage, $var_date);

push @array_out, \@array_temp2;

print "Sequence and assembly analysis:\n";
print "\tAccession:\t\t\t$var_accession\n";
print "\tOriginal reads:\t\t\t$var_ori_reads\n";
print "\tProcessed reads:\t\t$var_num_reads\n";
print "\tDropped reads:\t\t\t$var_dropped %\n";
print "\tAssembly length:\t\t$var_length bp\n";
print "\tGC:\t\t\t\t$var_GC %\n";
print "\tContigs:\t\t\t$var_contigs\n";
print "\tGenus:\t\t\t\t$var_genus\n";
print "\tKraken2 genus alignment:\t$var_align_genus %\n";
print "\tSpecies:\t\t\t$var_species\n";
print "\tKraken2 species alignment:\t$var_align_species %\n";
print "\tAvg genome length:\t\t$var_avg_length bp\n";
print "\tGenome ratio:\t\t\t$var_ratio\n";
print "\tCoverage:\t\t\t$var_coverage x\n";
print "\tDate analyzed:\t\t\t$var_date\n";

# --------------------------------------------------------------------------- #

# Write data in @array_out to $file_out:
open ( my $file_write, '>', $file_out ) or die $!;

for ( my $i = 0; $i < scalar @array_out; $i++ ) {

        my $var_string  = join ( "\t", @{ $array_out[$i]} );

        print $file_write "$var_string\n";

#	print "$var_string\n";

}

# Close $file_write:
close ( $file_write );

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

        # Return refernece to @array_out and end subroutine:
        return \@array_out;

}

# --------------------------------------------------------------------------- #

# Subroutine for pulling data from Kraken2 report:
sub Kraken2 {

        # Arguments:
        my ( $array_in ) = @_;

        # Data structures:
        my @array_in    = @$array_in;

        # Variables:
        my $var_genus		= "unknown";
        my $var_genus_align	= 0;
	my $var_species		= "unknown";
	my $var_species_align	= 0;

        # Iterate through @array_in and process:
        for ( my $i = 0; $i < scalar @array_in; $i++ ) {

                # Split string into a temporary array for extracting variables:
                my @array_temp  = split (" ", $array_in[$i]);

                $array_in[$i]   = \@array_temp;

        }

        @array_in       = sort { $a -> [0] <=> $b -> [0] } @array_in;

        # Iterate through @array_in and process:
        for ( my $i = 0; $i < scalar @array_in; $i++ ) {

                my $var_percent = $array_in[$i][0];
                my $var_rank    = $array_in[$i][3];

		next if $var_percent    < 30;

#		print "$i: @{$array_in[$i]}\n";

		# If ranking is at genus level record:
		if ( $var_rank eq "G" || $var_rank eq "G1" ) {

			my $var_scalar		= scalar @{$array_in[$i]};

			$var_genus		= $array_in[$i][$var_scalar-1];
			$var_genus_align	= $array_in[$i][0];

		}

		# If ranking is at the species level record:
		elsif ( $var_rank eq "S" ) {

			my $var_scalar  = scalar @{$array_in[$i]};

			$var_species_align      = $array_in[$i][0];
			$var_species		= $array_in[$i][$var_scalar-1];

		}

	}

        return ( $var_genus, $var_genus_align, $var_species, $var_species_align );

}

# --------------------------------------------------------------------------- #

# Subroutine for scrapping average genome length from NCBI HTML file:
sub Scrape {

        # Parameters:
        my ( $array_html )      = @_;

        # Data structures:
        my @array_html  = @$array_html;

        # Variables:
        my $var_avg_length;

        # Scrape average length from @array_html:
        for ( my $j = 0; $j < scalar @array_html; $j++ ) {

                if ( $array_html[$j] =~ /median total length/ ) {

                        my @array_temp  = split ( /[\>,\<,\:]+/, $array_html[$j] );

                        for ( my $k = 0; $k < scalar @array_temp; $k++ ) {

                                if ( $array_temp[$k] =~ /median total length/) {

                                        $var_avg_length = $array_temp[$k+1];

                                        $var_avg_length =~ s/^\s+//;

                                        last;

                                }

                        }

                }

        }

        # Return $var_avg_length and end subroutine:
        return $var_avg_length;

}

# --------------------------------------------------------------------------- #

