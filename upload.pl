#!/usr/bin/env perl

use strict;
use warnings;

# --------------------------------------------------------------------------- #

# File:                 upload.pl
# Date created:         15 July 2021
# Date last modified:   19 July 2021
# Author:               Eliot Stanton (eliot.stanton@state.mn.us)
# Description:          Wrapper for automating upload of trimmed and filtered
#			files to NCBI SRA and GenBank databases.

# --------------------------------------------------------------------------- #

# Variables imported by this script:
my $dir_in	= $ARGV[0];
my $dir_results	= $ARGV[1];

# Define variables used by script:
my $file_key	= "~/aspera.openssh";
my $file_ncbi	= "~/aspera.path";
my $dir_fastq	= "/home/mdh/shared/HAI_QC/.upload/fastq";
my $dir_fasta   = "/home/mdh/shared/HAI_QC/.upload/fasta";

# Convert file paths to realpath:
$file_key	= `realpath $file_key`;
chomp $file_key;
$dir_results	= 'results' unless $dir_results;
$dir_results	= `realpath $dir_results`;
chomp $dir_results;

#my $var_ncbi	= "subasp\@upload.ncbi.nlm.nih.gov:uploads/estanton\@wisc.edu_Npf4wODL";

# Define help file:
my $var_help	= "upload.pl [DIR_IN] [DIR_RESULTS]\n
\tDIR_IN: Directory containing original FASTQ files
\tDIR_RESULTS: Directory containing results for each isolate (default: results)
\tSSH key provided by NCBI should be located at ~/aspera.openssh
\tUpload filepath provided by NCBI should be located at ~/aspera.path 
	(ex. subasp\@upload.ncbi.nlm.nih.gov:uploads/username\@state.mn.us_Nkq3oWLD) 
\tFiles are upload into fastq and fasta directories";


# Data structures used by this script:
my %hash_in;
my @array_in;

# Import $var_ncbi from $file_ncbi:
my $var_ncbi	= `more $file_ncbi`;
chomp $var_ncbi;

# --------------------------------------------------------------------------- #

# If conditions aren't met inform user and kill script:
unless ( $dir_in && -e $dir_in && -e $dir_results && $file_key && $file_ncbi ) {

	print "$var_help\n\n";

	print "\tDIR_IN missing or not provided\n" unless $dir_in && -e $dir_in;
	print "\tDIR_RESULTS missing\n" unless -e $dir_results;
	print "\tFile containing SSH key not found\n" unless -e $file_key;
	print "\tFile containing upload path not found\n" unless -e $file_ncbi;

	exit;

}

# --------------------------------------------------------------------------- #

# Import accession numbers from $dir_in and store in @array_in:
opendir my $dir_read, "$dir_in" or die "Cannot open directory $dir_in!";

# Import contents of $dir_read into @array_fastq:
@array_in = readdir $dir_read;

# Close $dir_read;
closedir $dir_read;

# Remove . and .. from @array_in:
splice @array_in, 0, 2;

# Print $var_help and end script if $dir_in is empty:
die "$var_help \nPaired fastq files required in $dir_in!\n" unless scalar @array_in > 1;

# Store accessions in %hash_in:
for ( my $i=0; $i < scalar @array_in; $i++ ) {

	my $var_accession	= (split /\_/, $array_in[$i])[0];

	$hash_in {$var_accession}	= 1;

}

# Clear out @array_in:
@array_in	= ();

# Export keys with accessions from %hash_in to @array_in:
foreach my $var_accession ( keys %hash_in ) { push @array_in, "$var_accession" } 

# Sort elements in @array_in:
@array_in	= sort { $a cmp $b } @array_in;

# --------------------------------------------------------------------------- #

# Print message to user:
print "Uploading files to $var_ncbi:\n";

# Create symbolic links for filtered fastq files and trimmed fasta files:
for ( my $i=0; $i < scalar @array_in; $i++ ) {

	# Define accession and print to command-line:
	my $var_accession	= $array_in[$i];
	print "$i: $var_accession:\n";

	# Define FASTQ and FASTA filepaths and print to command-line:
	my $file_fastq1	= "$dir_results/$var_accession/$var_accession\_filtered_R1.fastq.gz";
        my $file_fastq2 = "$dir_results/$var_accession/$var_accession\_filtered_R2.fastq.gz";
	my $file_fasta	= "$dir_results/$var_accession/$var_accession\_trimmed.fa";
	print "\t$file_fastq1\n\t$file_fastq2\n\t$file_fasta\n";

	# Check that eacj file exists, if it doesn't warn user:
	print "\tERROR: $file_fastq1 NOT FOUND!\n" unless -e $file_fastq1;
        print "\tERROR: $file_fastq2 NOT FOUND!\n" unless -e $file_fastq2;
        print "\tERROR: $file_fasta NOT FOUND!\n" unless -e $file_fasta;

	# Create symbolic links in upload directorys $dir_fastq and $dir_fasta:
	system "ln -s $file_fastq1 $dir_fastq\n";
        system "ln -s $file_fastq2 $dir_fastq\n";
        system "ln -s $file_fasta $dir_fasta\n";

}

# --------------------------------------------------------------------------- #

# Run Aspera command for FASTQ files:
print "\nascp \n\t-i $file_key \n\t--symbolic-links=follow \n\t--overwrite=diff \n\t-QT \n\t-l199m \n\t-k1 \n\t-d $dir_fastq \n\t$var_ncbi\n";
system "module load aspera; ascp -i $file_key --symbolic-links=follow --overwrite=diff -QT -l100m -k1 -d $dir_fastq $var_ncbi";

# Run Aspera command for FASTA files:
print "\nascp \n\t-i $file_key \n\t--symbolic-links=follow \n\t--overwrite=diff \n\t-QT \n\t-l199m \n\t-k1 \n\t-d $dir_fasta \n\t$var_ncbi\n";
system "module load aspera; ascp -i $file_key --symbolic-links=follow --overwrite=diff -QT -l100m -k1 -d $dir_fasta $var_ncbi";

# Remove symbolic links from $dir_fastq and $dir_fasta:
system "rm $dir_fastq/*";
system "rm $dir_fasta/*";
