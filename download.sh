#!/bin/bash
#SBATCH --time=8:00:01
#SBATCH --mem=10g
#SBATCH --tmp=10g

# --------------------------------------------------------------------------- #

SRR=$1
THREADS=$2
PROPORTION=$3
DOWNLOADS=$4
DOWNSAMPLED=$5

FASTQ1=$SRR\_1.fastq.gz
FASTQ1R=$SRR\_R1.fastq.gz
FASTQ1_LOW=$DOWNSAMPLED/$SRR\-$PROPORTION\_R1.fastq.gz

FASTQ2=$SRR\_2.fastq.gz
FASTQ2R=$SRR\_R2.fastq.gz
FASTQ2_LOW=$DOWNSAMPLED/$SRR\-$PROPORTION\_R2.fastq.gz

# Load SRA module:
module load sratoolkit/2.8.2

# Download FASTQ files:
fastq-dump --gzip --split-files $SRR

# Unload SRA module:
module unload sratoolkit/2.8.2

# Rename FASTQ files:
mv $FASTQ1 $FASTQ1R
mv $FASTQ2 $FASTQ2R

chmod 755 $FASTQ1R
chmod 755 $FASTQ2R

mv $FASTQ1R $DOWNLOADS
mv $FASTQ2R $DOWNLOADS

# --------------------------------------------------------------------------- #

# Load SEqkit module:
module load seqkit/0.16.1

# Create low coverage versions of FASTQ files:
seqkit sample -j $THREADS -p 0.$PROPORTION -o $FASTQ1_LOW $DOWNLOADS/$FASTQ1R
seqkit sample -j $THREADS -p 0.$PROPORTION -o $FASTQ2_LOW $DOWNLOADS/$FASTQ2R

chmod 755 $FASTQ1_LOW
chmod 755 $FASTQ2_LOW

# Unload Seqkit module:
module unload seqkit/0.16.1
