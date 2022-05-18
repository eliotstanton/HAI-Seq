#!/bin/bash
#SBATCH --time=8:00:01
#SBATCH --mem=10g
#SBATCH --tmp=10g

# --------------------------------------------------------------------------- #

DIR_OUT=$1
THREADS=$2
FASTQ9=$3
FASTQ10=$4
SPADES_FASTA=$5
CONFIG=$6

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

staphb-tk \
	--docker_config $CONFIG \
	spades \
	-1 $FASTQ9 \
	-2 $FASTQ10 \
	-o $DIR_OUT \
	--cov-cutoff 2 \
	--careful \
	--threads $THREADS

# Copy assembly file t new name:
if [ -f "$DIR_OUT/contigs.fasta" ]; then

	cp $DIR_OUT/contigs.fasta $SPADES_FASTA

else 

	printf "$DIR_OUT/contigs.fasta not found! Exiting.\n"
	exit

fi

# --------------------------------------------------------------------------- #

# Clean up from SPAdes:
rm -rf $DIR_OUT/K127 $DIR_OUT/K99 $DIR_OUT/K77 $DIR_OUT/K55 $DIR_OUT/K33 $DIR_OUT/K21
rm -rf $DIR_OUT/tmp $DIR_OUT/misc $DIR_OUT/mismatch_corrector $DIR_OUT/pipeline_state
rm -rf $DIR_OUT/corrected
rm $DIR_OUT/params.txt $DIR_OUT/run_spades.sh $DIR_OUT/run_spades.yaml
rm $DIR_OUT/assembly_graph* $DIR_OUT/before_rr.fasta $DIR_OUT/contigs.paths
rm $DIR_OUT/dataset.info $DIR_OUT/input_dataset.yaml $DIR_OUT/scaffolds.paths

# --------------------------------------------------------------------------- #

# Run Quast:
time staphb-tk \
	--docker_config $CONFIG \
	quast \
	--threads $THREADS \
	--output-dir $DIR_OUT/quast \
	-1 $FASTQ9 -2 $FASTQ10 \
	$SPADES_FASTA \
