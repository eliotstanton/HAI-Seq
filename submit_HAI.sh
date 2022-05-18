#!/bin/bash
#SBATCH --time=8:00:01
#SBATCH --ntasks=1
#SBATCH --mem=2g
#SBATCH --tmp=2g

# --------------------------------------------------------------------------- #

# File:                 submit_HAI.sh
# Date created:         02 July 2021
# Date last modified:   15 February 2022
# Author:               Eliot Stanton (eliot.stanton@state.mn.us)
# Description:          Perform QC analysis, genome assembly and species ID on
#                       WGS data for upload to NCBI.

# --------------------------------------------------------------------------- #

# Add path for MDH modules:
export MODULEPATH=/home/mdh/shared/software_modules/modulefiles:$MODULEPATH

# Load StaphB-toolkit module:
module load sbtk/1.3.2

# Set location of the HAI_QC directory and scripts:
HAI_PATH="/home/mdh/shared/HAI_QC"
SCRIPT_PATH="/home/mdh/shared/software_modules/HAI_QC/1.1"

HAI_PATH=`realpath $HAI_PATH`
SCRIPT_PATH=`realpath $SCRIPT_PATH`

# --------------------------------------------------------------------------- #

# Define arguments passed to the script from the command-line:
DIR_IN=$1
ACCESSION=$2
DIR_OUT=$3

DIR_IN=`realpath $DIR_IN`
DIR_OUT=`realpath $DIR_OUT`

# Define additional arguments that may need to be changed in future:
THREADS=8
KRAKEN_DB="/panfs/roc/msisoft/kraken/kraken_db"

# Define variable for error reporting:
VAR_ERROR=0

# Define final output directory for files:
DIR_OUT2="$DIR_OUT/$ACCESSION"
#DIR_OUT2=`realpath $DIR_OUT2`

# Define location of config used by staphb-toolkit file:
CONFIG_JSON="$SCRIPT_PATH/config.json"

# Define the location of the phiX fasta file used for filtering:
PHIX="$SCRIPT_PATH/phiX.fa"
#PHIX="phiX/phiX.fa"

# Define the location of original FASTQ files:
FASTQ1=$DIR_IN/$ACCESSION\_R1.fastq.gz
FASTQ2=$DIR_IN/$ACCESSION\_R2.fastq.gz

# Define the locations of filtered and trimmed FASTQ files:
FASTQ3=$DIR_OUT2/$ACCESSION\_trimmed_R1.fastq
FASTQ4=$DIR_OUT2/$ACCESSION\_trimmed_R2.fastq
FASTQ5=$DIR_OUT2/$ACCESSION\_trimmed_unpaired_R1.fastq
FASTQ6=$DIR_OUT2/$ACCESSION\_trimmed_unpaired_R2.fastq
FASTQ7=$DIR_OUT2/$ACCESSION\_filtered.fastq
FASTQ8=$DIR_OUT2/$ACCESSION\_phiX.fastq
FASTQ9=$DIR_OUT2/$ACCESSION\_filtered_R1.fastq
FASTQ10=$DIR_OUT2/$ACCESSION\_filtered_R2.fastq

# Define the location of Kraken output and report file:
KRAKEN_OUTPUT=$DIR_OUT2/$ACCESSION.kraken
KRAKEN_REPORT=$DIR_OUT2/$ACCESSION\_kraken2_report.txt

# Define the location of SPADES FASTA files:
SPADES_FASTA=$DIR_OUT2/$ACCESSION.fa
SPADES_TRIMMED=$DIR_OUT2/$ACCESSION\_trimmed.fa

# Define the location of MLST file:
MLST=$DIR_OUT2/$ACCESSION\_mlst.txt

# Define help message:
HELP="submit.sh [FASTQ_DIRECTORY] [ACCESSION] [OUTPUT_DIRECTORY]

    FASTQ_DIRECTORY: Directory containing FASTQ files
    ACCESSION: Accession number of sample to be analyzed (YYYYEL-####)
    OUTPUT_DIRECTORY: A subdirectory containing results will be created here

    FASTQ files should be formatted with the following formatting:
	 YYYYEL-####_R1.fastq.gz and YYYY-####_R2.fastq.gz.

    Files in OUTPUT_DIRECTORY/ACCESSION include:
	ACCESSION_filtered_R1.fastq.gz
	ACCESSION_filtered_R2.fastq.gz
	ACCESSION_trimmed.fa
	ACCESSION_kraken2_report.txt
	ACCESSION_stats.txt"

# --------------------------------------------------------------------------- #

# Handle not enough arguments being supplied to the script:
if [[ ! $3 ]]; then
        printf "ERROR: Incomplete arguments provided.\n\n"
        printf "$HELP\n\n"
        echo "Exiting."; exit

fi

# Check if $DIR_OUT exists:
if [[ ! -e $DIR_OUT ]]; then
        echo "ERROR: $DIR_OUT not found!" 
	echo "Exiting."; exit
fi

# Check if staphb-tk is working:
if ! command -v staphb-tk &> /dev/null; then
        echo "Unable to find staphb-tk!"
	echo "Exiting.\n"
        exit
fi

# Check if staphb-tk exits correctly:
command staphb-tk --help &> /dev/null
if [ $? != 0 ]; then
        printf "staphb-tk exited with error! Exiting.\n"
        staphb-tk
        exit
fi

# Test for presence of $PHIX:
if [[ ! -f $PHIX ]]; then
        echo "ERROR: PhiX fasta file ($PHIX) not found!"
	echo "Exiting."; exit
fi

# Test for presence of $KRAKEN_DB:
if [[ ! -e $KRAKEN_DB ]]; then
        echo "ERROR: Kraken2 database ($KRAKEN_DB) not found!"
	echo "Exiting."; exit

fi

# Test for presence of $FASTQ1 and $FASTQ2:
if [[ ! -f $FASTQ1 ]]; then
        echo "ERROR: $FASTQ1 not found!"
	printf "$HELP"
	echo "Exiting."; exit

fi

if [[ ! -f $FASTQ2 ]]; then
        echo "ERROR: $FASTQ2 not found!"
	printf "$HELP"
	echo "Exiting."; exit
fi

if [[ $UPLOAD ]]; then

	module load aspera

	$SCRIPT_PATH/upload.pl $DIR_IN $DIR_OUT

fi

# --------------------------------------------------------------------------- #

# Make directory for processed files as needed 
[ ! -d $DIR_OUT2 ] && mkdir $DIR_OUT2

# Modify permissions for directory containing processed files:
chmod 770 $DIR_OUT2

# Modify permissions for directory containing FASTQ files:
chmod 770 -R $DIR_IN

# Log output from script:
exec 1> >(tee $DIR_OUT2/$ACCESSION-bash.out)

# Print file details to command line:
printf "\nVERSION:\t1.1\n"
printf "ACCESSION:\t$ACCESSION\n"
printf "OUTPUT:\t\t$DIR_OUT2\n"
printf "FASTQ1:\t\t$FASTQ1\n"
printf "FASTQ2:\t\t$FASTQ2\n"
printf "phiX: \t\t$PHIX\n\n"

#: <<'END'

# Create files with md5 checksum for FASTQ files:
md5sum $FASTQ1 > $DIR_OUT2/$ACCESSION\_R1.fastq.gz.md5  
md5sum $FASTQ2 > $DIR_OUT2/$ACCESSION\_R2.fastq.gz.md5

# --------------------------------------------------------------------------- #

# Submit the initial job trimming and filtering reads:
JOBID1=$(sbatch \
        -p small \
        --parsable \
        --job-name="trim-filter-$ACCESSION" \
        --output="$DIR_OUT2/$ACCESSION-trim-filter.out" \
        --cpus-per-task=$THREADS \
        $SCRIPT_PATH/trim-filter.sh \
        $THREADS $PHIX \
        $FASTQ1 $FASTQ2 \
        $FASTQ3 $FASTQ4 \
        $FASTQ5 $FASTQ6 \
        $FASTQ7 $FASTQ8 \
        $FASTQ9 $FASTQ10 \
        $CONFIG_JSON $SCRIPT_PATH \
	$DIR_IN $DIR_OUT2 )
printf "\t- Submitted job $JOBID1 to trim and filter reads using Trimmomatic and BBmaps\n"

# --------------------------------------------------------------------------- #

# Identify species using Kraken2:
JOBID2=$(sbatch \
	-p small \
	--parsable \
	--job-name="kraken2-$ACCESSION" \
	--output="$DIR_OUT2/$ACCESSION-kraken2.out" \
	--cpus-per-task=$THREADS \
	--dependency=afterok:$JOBID1 \
	$SCRIPT_PATH/kraken2.sh \
	$ACCESSION $THREADS \
	$DIR_OUT2 $KRAKEN_DB \
	$FASTQ9 $FASTQ10 \
	$KRAKEN_REPORT $CONFIG_JSON )
printf "\t- Submitted job $JOBID2 to run species identification using Kraken2\n"

# Produce an assembly using SPAdes:
JOBID3=$(sbatch \
        -p small \
        --parsable \
        --job-name="spades-$ACCESSION" \
        --output="$DIR_OUT2/$ACCESSION-spades.out" \
        --cpus-per-task=$THREADS \
        --dependency=afterok:$JOBID1 \
        $SCRIPT_PATH/spades.sh \
        $DIR_OUT2 $THREADS \
        $FASTQ9 $FASTQ10 \
	$SPADES_FASTA $CONFIG_JSON )
printf "\t- Submitted job $JOBID3 to produce genome assembly using SPAdes\n"

# Run MLST on SPAdes assembly:
JOBID4=$(sbatch \
	-p small \
	--parsable \
	--job-name="MLST-$ACCESSION" \
	--output="$DIR_OUT2/$ACCESSION-mlst.out" \
	--cpus-per-task=$THREADS \
	--dependency=afterok:$JOBID3 \
	$SCRIPT_PATH/MLST.sh \
	$SPADES_FASTA $MLST \
	$CONFIG_JSON $THREADS )
printf "\t- Submitted job $JOBID4 to identify MLST using SPAdes assembly\n"

# --------------------------------------------------------------------------- #

printf "\n"

# Run script to get deliverables, use sbatch if running as Slurm submission
# use srun if running interactively within terminal:
if [ -n "$SLURM_JOB_ID" ]
then
	sbatch \
		-p small \
		--dependency=afterok:$JOBID2:$JOBID3 \
		--job-name="analysis-$ACCESSION" \
		--output="$DIR_OUT2/$ACCESSION-analysis.out" \
		--wait \
		$SCRIPT_PATH/analysis.sh \
		$SCRIPT_PATH $ACCESSION \
		$DIR_IN $DIR_OUT $FASTQ9 $FASTQ10 \
		$KRAKEN_REPORT $SPADES_FASTA

	FASTQ9=`realpath $FASTQ9`
	FASTQ10=`realpath $FASTQ10`
	KRAKEN_REPORT=`realpath $KRAKEN_REPORT`
	SPADES_FASTA=`realpath $SPADES_FASTA`
	SPADES_TRIMMED=`realpath $SPADES_TRIMMED`

else
	srun \
		--dependency=afterok:$JOBID2:$JOBID3 \
		--job-name="analysis-$ACCESSION" \
		$SCRIPT_PATH/analysis.sh \
		$SCRIPT_PATH $ACCESSION \
		$DIR_IN $DIR_OUT $FASTQ9 $FASTQ10 \
		$KRAKEN_REPORT $SPADES_FASTA

fi

# --------------------------------------------------------------------------- #

# Check if $FASTQ9 exists:
if [[ ! -e $FASTQ9 ]]; then

	printf "ERROR: $FASTQ9 not found!\n" && VAR_ERROR=1

fi

# Check if $FASTQ10 exists:
if [[ ! -e $FASTQ10 ]]; then

	printf "ERROR: $FASTQ10 not found!\n" && VAR_ERROR=1

fi

# Check if $KRAKEN_REPORT exists:
if [[ ! -e $KRAKEN_REPORT ]]; then

	printf "ERROR: $KRAKEN_REPORT not found!\n" && VAR_ERROR=1

fi

# Check if $SPADES_FASTA exists:
if [[ ! -e $SPADES_FASTA ]]; then

	printf "ERROR: $SPADES_FASTA not found!\n" && VAR_ERROR=1

fi

if [[ $VAR_ERROR == 1 ]]; then

	printf "Exiting.\n\n" && exit "$VAR_ERROR"

fi

# --------------------------------------------------------------------------- #

# Run script to remove contigs smaller than 500 bp from $SPADES_FASTA file:
$SCRIPT_PATH/removesmall.pl 500 $SPADES_FASTA > $SPADES_TRIMMED

# Change permissions recursively for all the new files within $DIR_OUT2:
chmod -R 770 $DIR_OUT2

# Compress remaining $FASTQ files:
printf "\nCompressing FASTQ files:\n\t$FASTQ8\n\t$FASTQ9\n\t$FASTQ10\n"
gzip -f $FASTQ8
gzip -f $FASTQ9
gzip -f $FASTQ10
gzip -f $KRAKEN_OUTPUT
printf "Complete.\n"
