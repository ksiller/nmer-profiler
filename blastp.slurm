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

TASK_NO=$(printf "%04d" ${SLURM_ARRAY_TASK_ID})

# set output dir and file, remove previous output file
OUTPUTDIR="blastp-${SLURM_ARRAY_JOB_ID}"
mkdir -p ${OUTPUTDIR}
OUTPUTFILE="${OUTPUTDIR}/aligned-task-${TASK_NO}.txt"
if [ -f "$OUTPUTFILE" ]; then
    rm ${OUTPUTFILE}
fi

# set input file. Each line in input file should specify a fasta file with 1 or more amino acid sequences 
DEFFILE="input.txt"
AAFILE=${1:-$DEFFILE}
if [ ! -f "$AAFILE" ]; then
    echo "Invalid aa list file. File ${AAFILE} does not exist. Provide alternative input file as command line argument."
    exit
fi

# set TAXON and create list of species TAXIDS
DEFTAXID=9443 # 9443:primates; 9606:Homo sapiens; 32524:Amniota
TAXID=${2:-$DEFTAXID}
TAXIDS_FILE="${OUTPUTDIR}/${TAXID}.taxids"
get_species_taxids.sh -t ${TAXID} > ${TAXIDS_FILE}

# set output format and e-value cutoff
FORMAT="qseqid qseq sseqid sseq slen qstart qend length mismatch gapopen gaps score evalue"
FORMATCSV=$(echo ${FORMAT} | tr " " ",")
SHORTOPTS="-word_size 2 -gapopen 9 -matrix PAM30 -threshold 16 -window_size 15 "
EVALUE=4.7

# process one fasta file per task
interval=1                                        # defines # of fasta files to process
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
    if [ ! -f "$aa" ]; then
        echo "File $aa not found."
    else
        echo "Blast results for: ${aa}, TAXID=${TAXID}" >> ${OUTPUTFILE}
        echo ${FORMATCSV} >> ${OUTPUTFILE}
        blastp ${SHORTOPTS} \
           -num_threads ${SLURM_CPUS_PER_TASK} \
           -taxidlist ${TAXIDS_FILE} \
           -query ${aa} \
           -db nr \
           -evalue ${EVALUE} \
           -outfmt "10 ${FORMAT}" >> ${OUTPUTFILE}
    fi
done
