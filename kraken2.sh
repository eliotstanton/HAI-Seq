#!/bin/bash -l
#SBATCH --time=8:00:01
#SBATCH --mem=38g
#SBATCH --tmp=48g

# --------------------------------------------------------------------------- #

ACCESSION=$1
THREADS=$2
DIR_OUT=$3
KRAKEN_DB=$4
FASTQ9=$5
FASTQ10=$6
KRAKEN_REPORT=$7
CONFIG=$8

# --------------------------------------------------------------------------- #

# Check if $DIR_OUT exists:
if [[ ! -e $DIR_OUT ]]; then

        echo "ERROR: $DIR_OUT not found! Exiting."; exit

fi

# Check if $FASTQ9 exists:
if [[ ! -e $FASTQ9 ]]; then

        echo "ERROR: $FASTQ9 not found! Exiting."; exit

fi

# Check if $FASTQ10 exists:
if [[ ! -e $FASTQ10 ]]; then

        echo "ERROR: $FASTQ10 not found! Exiting."; exit

fi

# --------------------------------------------------------------------------- #

time staphb-tk \
	--docker_config $CONFIG \
	kraken2 \
	--db $KRAKEN_DB \
	--threads $THREADS \
	--output $DIR_OUT/$ACCESSION.kraken \
	--use-names \
	--report $KRAKEN_REPORT \
	--paired $FASTQ9 $FASTQ10
