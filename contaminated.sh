#!/bin/bash
#SBATCH --time=8:00:01
#SBATCH --mem=10g
#SBATCH --tmp=10g

# --------------------------------------------------------------------------- #

SRR1=$1
SRR2=$2
THREADS=$3
PROPORTION=$4
DOWNLOADS=$5
CONTAMINATED=$6

FASTQ1=$DOWNLOADS/$SRR1\_R1.fastq.gz
FASTQ2=$DOWNLOADS/$SRR1\_R2.fastq.gz
FASTQ3=$DOWNLOADS/$SRR2\_R1.fastq.gz
FASTQ4=$DOWNLOADS/$SRR2\_R2.fastq.gz

FASTQ1_LOW=$SRR1-$SRR2/$SRR1\-$PROPORTION\_R1.fastq
FASTQ2_LOW=$SRR1-$SRR2/$SRR1\-$PROPORTION\_R2.fastq
FASTQ3_LOW=$SRR1-$SRR2/$SRR2\-$PROPORTION\_R1.fastq
FASTQ4_LOW=$SRR1-$SRR2/$SRR2\-$PROPORTION\_R2.fastq

FASTQ_MERGE1=$CONTAMINATED/$SRR1\-$SRR2\_R1.fastq
FASTQ_MERGE2=$CONTAMINATED/$SRR1\-$SRR2\_R2.fastq

# --------------------------------------------------------------------------- #

# Load SEqkit module:
module load seqkit/0.16.1

# Make directory for holding FASTA files:
mkdir $SRR1-$SRR2

# Create low coverage versions of FASTQ files:
seqkit sample -j $THREADS -p 0.$PROPORTION $FASTQ1 > $FASTQ1_LOW
seqkit sample -j $THREADS -p 0.$PROPORTION $FASTQ2 > $FASTQ2_LOW
seqkit sample -j $THREADS -p 0.$PROPORTION $FASTQ3 > $FASTQ3_LOW
seqkit sample -j $THREADS -p 0.$PROPORTION $FASTQ4 > $FASTQ4_LOW

# Concatenate low coverage versions together:
cat $FASTQ1_LOW $FASTQ3_LOW > $FASTQ_MERGE1
cat $FASTQ2_LOW $FASTQ4_LOW > $FASTQ_MERGE2

# Remove the low coverage FASTQ files:
rm -rf $SRR1-$SRR2

# Compress merged FASTQ files:
gzip $FASTQ_MERGE1
gzip $FASTQ_MERGE2

# Unload Seqkit module:
module unload seqkit/0.16.1

chmod 755 $FASTQ_MERGE1
chmod 755 $FASTQ_MERGE2
