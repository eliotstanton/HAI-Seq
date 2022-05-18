#!/bin/bash

# --------------------------------------------------------------------------- #

SPADES_FASTA=$1
MLST=$2
CONFIG=$3
THREADS=$4

# --------------------------------------------------------------------------- #

# Check if $SPADES_FASTA exists:
if [[ ! -e $SPADES_FASTA ]]; then
        echo "ERROR: $SPADES_FASTA not found! Exiting."; exit
fi

# --------------------------------------------------------------------------- #

# Run MLST:
time staphb-tk \
	--docker_config $CONFIG \
	mlst \
	--threads $THREADS \
	$SPADES_FASTA > $MLST

# --------------------------------------------------------------------------- #
