#!/bin/bash
#SBATCH --time=8:00:01
#SBATCH --mem=10g
#SBATCH --tmp=10g

# --------------------------------------------------------------------------- #

# Arguments passed to this script:
THREADS=$1
PHIX=$2
FASTQ1=$3
FASTQ2=$4
FASTQ3=$5
FASTQ4=$6
FASTQ5=$7
FASTQ6=$8
FASTQ7=$9
FASTQ8=${10}
FASTQ9=${11}
FASTQ10=${12}
CONFIG=${13}
SCRIPT_PATH=${14}
DIR_IN=${15}
DIR_OUT=${16}

# --------------------------------------------------------------------------- #

# Trim/filter FASTQ files:
printf "* Trimming and filtering reads using Trimmomatic:\n\t"
printf "$PHIX"
singularity \
	exec \
	-B $SCRIPT_PATH,$DIR_IN,$DIR_OUT \
	$SCRIPT_PATH/singularity/staphb-trimmomatic-0.39.sif \
	trimmomatic PE \
	-threads $THREADS \
	-phred33 \
	$FASTQ1 $FASTQ2 \
	$FASTQ3 $FASTQ5 $FASTQ4 $FASTQ6 \
	ILLUMINACLIP:/Trimmomatic-0.39/adapters/NexteraPE-PE.fa:2:30:10 \
	LEADING:20 \
	TRAILING:20 \
	MINLEN:50 \
	AVGQUAL:30

# Filter out phiX reads using Bbtools:
printf "* Filtering reads aligned to PhiX genome using BBtools\n\t"
singularity \
	exec \
	-B $SCRIPT_PATH,$DIR_OUT \
	$SCRIPT_PATH/singularity/staphb-bbtools-38.76.sif \
	/bbmap/bbmap.sh \
	threads=$THREADS \
	ref=$PHIX nodisk \
	in=$FASTQ3 \
	in2=$FASTQ4 \
	outu=$FASTQ7 \
	outm=$FASTQ8

printf "\t"

# Split filtered reads into R1 and R2 files:
singularity \
	exec \
	-B $SCRIPT_PATH,$DIR_OUT \
	$SCRIPT_PATH/singularity/staphb-bbtools-38.76.sif \
	/bbmap/reformat.sh \
	overwrite=true \
	in=$FASTQ7 \
	out1=$FASTQ9 \
	out2=$FASTQ10


# Cleanup FASTQ files:
rm $FASTQ3 $FASTQ4 $FASTQ5 $FASTQ6 $FASTQ7
