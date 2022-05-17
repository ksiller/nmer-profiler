# nmer-profiler

The nmer-profiler is a multi-stage bioinformatics pipeline that identifies unmatched short peptide sequences against a reference protein database, and performs a structural prediction on peptide candidates.

## Requirements

* **Stage 1:** blastp
* **Stage 2:** Alphafold (&tbd)


## FASTA Input Files

A set of peptide sequences in FASTA format. For high-throughput parallel processing, candidate peptide sequences should be divided up into non-overlapping sets of files. Care should be taken that each peptide sequence has a unique FASTA id. The FASTA id is written as `qseqid` into the blastp results files. 

**Example files:** 

`blast-1_100.faa`
```
>Peptide 1
AFFLDNHQEATEGGHNMEDASTRWV
>Peptide 2
SSYVLVFSITRLINKIAGSVNILIP
>Peptide 3
ADRINNYLNLDRLWRDVHNLVIVHS
...
```

`blast-101_200.faa`
```
>Peptide 101
VPEYLGASVQPLIVLSAHQILFPLV
>Peptide 102
WIKIVEYGRIAKDNHLLGEERKQRN
>Peptide 103
ISLENLHKTKTRLLPEMLNYSVLFV
...
```

## Stage 1: Analysis (HPC SLURM)

To setup parallel processing we need to create an `input.txt` file that lists all the individual FASTA filenames. In the example case all FASTA file match this pattern: `blast-*.faa`.  If we assume that all FASTA files are located in the current directory, we can create the `input.txt` file like so:

```
find . -name "blast-*.faa" > input.txt
FILE_NO=$(wc -l input.txt | cut -d ' ' -f 1 )
```

The last command outputs the number of lines in the `input.txt` file and stores it in the `FILE_NO` environemnt variable. 

For efficient processing we will launch a job array on an HPC cluster. The array size matches the `FILE_NO`. The blastp.slurm job script assumes that cluster resource are managed through [SLURM](https://slurm.schedmd.com) and that the `blastp` program is available as an [lmod](https://lmod.readthedocs.io/en/latest/) module.

```
sbatch --array=1-${FILENO} blastp.slurm input.txt
```

