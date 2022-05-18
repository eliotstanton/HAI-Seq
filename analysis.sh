#!/bin/bash
#SBATCH --time=8:00:01
#SBATCH --ntasks=1
#SBATCH --mem=2g
#SBATCH --tmp=2g

SCRIPT_PATH=$1
ACCESSION=$2
DIR_IN=$3
DIR_OUT=$4
FASTQ9=$5
FASTQ10=$6
KRAKEN_REPORT=$7
SPADES_FASTA=$8

# Test for presence of $FASTQ9 and $FASTQ10:
if [[ ! -f $FASTQ9 ]]; then
        echo "ERROR: $FASTQ9 not found! Exiting." exit
fi

if [[ ! -f $FASTQ10 ]]; then
        echo "ERROR: $FASTQ10 not found! Exiting."; exit
fi

# Test for presence of $KRAKEN_REPORT:
if [[ ! -e $KRAKEN_REPORT ]]; then
        echo "ERROR: $KRAKEN_REPORT not found! Exiting"; exit
fi

# Test for presence of $SPADES_FASTA:
if [[ ! -f $SPADES_FASTA ]]; then
        echo "ERROR: $SPADES_FASTA not found! Exiting"; exit
fi

$SCRIPT_PATH/analysis.pl $ACCESSION $DIR_IN $DIR_OUT


