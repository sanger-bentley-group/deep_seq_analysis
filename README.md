# Deep sequencing pipeline for the farm

_Author: Victoria Dyster_

_Credits:_

- _Adapted from Gerry Tonkin-Hill's [pipeline](https://www.nature.com/articles/s41564-022-01238-1)_

- _Ana Ferreira for running the QC and PopPUNK to get GPSCs for the isolates_

- _Gemma Murray for help getting started_

## Introduction

This pipeline deconvolutes mixed-microbial reads into designated groups (e.g. multiple `Streptococcus pneumonaie` into GPSCs), assembles the deconvoluted reads and gets the serotypes.

## Download these scripts

In your lustre, download this repo.

```
git clone https://github.com/blue-moon22/deep_seq_analysis.git
cd deep_seq_analysis
```

## Create a reference database (using lanes from pf)

1. **Get your isolate assemblies**

First go into your lustre and create a directory for your analysis. 

```
mkdir -p data
```

Then create symlinks of isolate assemblies from a list of lanes.

```
module load pf

pf assembly -i <list of reference lanes file> -t file -l <output directory>
```

For example:

```
pf assembly -i /nfs/users/nfs_v/vc11/scratch/DATABASES/lays_isolates/lanes.txt -t file -l $(pwd)/data/assemblies
```

2. **Combine isolate assemblies to make one reference FASTA (only lanes that have passed QC\*)**

```
module load bsub.py

bsub.py 16 combine_fastas ./run_combine_fastas.sh <list of reference lanes file> <assemblies directory> <output combined fna file>
```

For example:

```
bsub.py 16 combine_fastas ./run_combine_fastas.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_passed.txt /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/assemblies /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/combined_vietnam.fna
```

_\*If you are using GPS, ask a team member where the list of passed lanes can be found_

## Check your reference database

Classifying your reads to lineages from your deep-sequenced mixed-microbial sample requires a comprehensive reference database that is representative of the microbial diversity in the geographical region and time frame. For example, it is unlikely you will get an accurate final outcome of this analysis if you're analysing mixed-microbial sequences in Country A using a reference database containing very few isolate genomes from Country A. To quickly check whether your reference isolates will be sufficient for your analysis, we use mash.

1. **Create mash sketch (i.e. mash reference) using your reference lanes**

```
./run_mash_sketch.sh \
    <list of reference lanes> \
    <assemblies directory> \
    <output mash sketches directory>
```

For example:

```
./run_mash_sketch.sh \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_passed.txt \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/assemblies \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/mash_sketches_vietnam
```

2. **Run mash paste (i.e. combine mash references)**

```
module load bsub.py

bsub.py 16 mash_paste ./run_mash_paste.sh <mash sketches directory> <output mash file>
```

For example:

```
bsub.py 16 mash_paste ./run_mash_paste.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/mash_sketches_vietnam /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/vietnam_combined.msh
```

3. **Run mash screen (i.e. map deep sequences against mash reference)**

```
bsub.py 16 mash_screen ./run_mash_screen.sh <list of deep seq lanes file> <output mash screens directory> <combine mash reference>
```

For example:

```
bsub.py 16 mash_screen ./run_mash_screen.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_6461.txt /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/mash_output_vietnam_6461 /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/vietnam_combined.msh
```

## Run mSWEEP Pipeline

1. **Build Themisto index on this reference**

```
./run_themisto_build.sh \
    <reference fna> \
    <output themisto index>
```

For example:

```
./run_themisto_build.sh \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/combined_vietnam.fna \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/themisto_index_vietnam
```

2. **Run themisto align and mSWEEP**

You will also need:
- Seroba database
- GPSC assignment external clusters csv for your reference lanes (from popPUNK)

```
./run_msweep_pipeline.sh \
    <list of deep seq lanes file> \
    <list of reference lanes file> \
    <reference fna> \
    <themisto index> \
    <gpsc assignment csv> \
    <seroba database> \
    <msweep output directory>
```

For example:

```
./run_msweep_pipeline.sh \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/deep_seq_lanes.txt \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_passed.txt \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/combined_vietnam.fna \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/themisto_index_vietnam \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/GPSC_assignment_external_clusters.csv \
    /nfs/users/nfs_g/gt4/lustre/maela_deep/msweep/seroba/database \
    /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/msweep_output
```

## Outputs from pipeline

The output files can be found in study folders within the msweep output directory you specified above. Each output is separated in directories called by the lane id of the deep sequence and number of reads that they were subsampled to and contain:

- `mSWEEP_abundances.txt`: the relative proportion of GPSCs
- `seroba_calls.txt`: the serotypes found
- `fastq.gz` files: the reads that have been identified belonging to a particular GPSC
- directories named after the GPSC number: contain the assemblies of the GPSCs as `contigs.fa` and the serotype in `*_seroba` directory _(Note: NA may exist if there were alignments to isolate genome(s) that had no GPSC)_
- `tmp` directory: contains the alignment files where the deep sequences were aligned (with Themisto) to the reference

## Build phylogenetic trees from output deconvoluted reads

Create phylogenetic trees from deconvoluted reads [using snippy, gubbins, snp-sites and FastTree](https://github.com/tseemann/snippy)

In the scripts directory:
```
# Create an input.txt file for snippy
find /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/msweep_output/6461/*/ /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/msweep_output/6463/*/ -type f -name "*_1.fastq.gz" > ../data/path_to_reads_1.txt
find /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/msweep_output/6461/*/ /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/msweep_output/6463/*/ -type f -name "*_2.fastq.gz" > ../data/path_to_reads_2.txt
cat ../data/path_to_reads_1.txt | awk -F/ '{print $12"_"$13}' | awk -F'_1.fastq.gz' '{print $1}' > ../data/msweep_samples.txt
paste -d $'\t' ../data/msweep_samples.txt ../data/path_to_reads_1.txt ../data/path_to_reads_2.txt | grep -v "_NA" > ../data/snippy_input.tab

# Build trees (tested with 10)
head ../data/snippy_input.tab > ../data/snippy_input_head.tab
bsub -G team284 -q normal -J build_tree -o ../log/build_tree.out -e ../log/build_tree.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 -n 4 "./run_build_trees.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/snippy_input_head.tab /data/pam/applications/vr-pipelines/refs/Streptococcus/pneumoniae_ATCC_700669/Streptococcus_pneumoniae_ATCC_700669_v1.fa 4 ../data/test_build_tree"

# Build trees (not implemented)
bsub -G team284 -q normal -J build_tree -o ../log/build_tree.out -e ../log/build_tree.err -R"span[hosts=1]" -R "select[mem>64000] rusage[mem=64000]" -M64000 -n 16 "./run_build_trees.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/snippy_input.tab /data/pam/applications/vr-pipelines/refs/Streptococcus/pneumoniae_ATCC_700669/Streptococcus_pneumoniae_ATCC_700669_v1.fa 16 <your_output_directory_here>"
```

