#!/bin/bash
#SBATCH -A laurielabblast
#SBATCH -p standard
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=1
#SBATCH -t 00:10:00

module purge
module load blast

export BLASTDB=/project/laurielab/nr-refs/

TAXID=9606 # Homo sapiens
FORMAT="qseqid qseq sseqid sseq slen qstart qend length mismatch gapopen gaps score evalue"
FORMATCSV=$(echo ${FORMAT} | tr " " ",")
SHORTOPTS="-word_size 2 -gapopen 9 -matrix PAM30 -threshold 16 -window_size 15 "
EVALUE=4.7

DEFFILE="input.txt"
AAFILE=${1:-$DEFFILE}
if [ ! -f "$AAFILE" ]; then
    echo "Invalid aa list file. File ${AAFILE} does not exist. Provide alternative input file as command line argument."
    exit
fi

TASK_NO=$(printf "%04d" ${SLURM_ARRAY_TASK_ID})

# set output dir and file, remove previous output file
OUTPUTDIR="blastp-${SLURM_ARRAY_JOB_ID}"
mkdir -p ${OUTPUTDIR}
OUTPUTFILE=${OUTPUTDIR}/aligned-task-${TASK_NO}.txt
if [ -f "$OUTPUTFILE" ]; then
    rm ${OUTPUTFILE}
fi

interval=1                                        # defines # of input sequences to process
start=$(( $SLURM_ARRAY_TASK_ID * $interval ))     # start line in AAFILE for first sequence
end=$(( $start + $interval - 1 ))                 # end line in AAFILE for last sequence

# no of sequences in input AAFILE
no_lines=$( wc -l "$AAFILE" | cut -d ' ' -f 1 )

# run the blastp search and aggregate results in OUTPUTFILE
for i in $(seq $start $end); do 
    if [ $i -gt $no_lines ]; then
        break
    fi
    aa=$( sed "${i}q;d" $AAFILE)
    echo "Blast results for: ${aa}" >> ${OUTPUTFILE}
    echo ${FORMATCSV} >> ${OUTPUTFILE}
    blastp ${SHORTOPTS} \
           -num_threads ${SLURM_CPUS_PER_TASK} \
           -query ${aa} \
           -db nr \
           -evalue ${EVALUE} \
           -taxids ${TAXID} \
           -outfmt "10 ${FORMAT}" >> ${OUTPUTFILE}
done
