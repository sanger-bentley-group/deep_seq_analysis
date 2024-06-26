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
git clone https://github.com/sanger-bentley-group/deep_seq_analysis.git
cd deep_seq_analysis
```

## Create a reference database

1. **Get your isolate assemblies (only lanes that have passed QC\*)**

First go into your lustre and create a directory for your analysis. 

```
mkdir -p data
```

Create a directory with all your assemblies in

For example:

```
mkdir -p data/assemblies
```

_\*If you are using GPS, ask a team member where the list of passed samples can be found_

2. **Combine isolate assemblies to make one reference FASTA**

In the scripts directory:

```
./run_combine_fastas.sh <assemblies directory> <output combined fna file>
```

For example:

```
./run_combine_fastas.sh data/assemblies combined_vietnam_ref.fna
```

## Check your reference database

Classifying your reads to lineages from your deep-sequenced mixed-microbial sample requires a comprehensive reference database that is representative of the microbial diversity in the geographical region and time frame. For example, it is unlikely you will get an accurate final outcome of this analysis if you're analysing mixed-microbial sequences in Country A using a reference database containing very few isolate genomes from Country A. To quickly check whether your reference isolates will be sufficient for your analysis, we use mash.

1. **Create mash sketch (i.e. mash reference) using your reference lanes**

```
./run_mash_sketch.sh \
    <assemblies directory> \
    <output mash sketches directory>
```

For example:

```
./run_mash_sketch.sh \
    /data/pam/team284/shared/deep_seq/data/assemblies \
    /data/pam/team284/shared/deep_seq/data/mash_sketches_vietnam_ref
```

2. **Run mash paste (i.e. combine mash references)**

```
bsub.py 8 mash_paste ./run_mash_paste.sh <mash sketches directory> <output mash file>
```

For example:

```
bsub.py 8 mash_paste ./run_mash_paste.sh /data/pam/team284/shared/deep_seq/data/mash_sketches_vietnam_ref /data/pam/team284/shared/deep_seq/data/vietnam_combined_ref.msh
```

3. **Run mash screen (i.e. map deep sequences against mash reference)**

```
./run_mash_screen.sh <fastq_folder> <combined mash reference> <output mash screens directory>
```

For example:

```
./run_mash_screen.sh /data/pam/team284/shared/deep_seq/data/fastqs /data/pam/team284/shared/deep_seq/data/vietnam_combined_ref.msh /data/pam/team284/shared/deep_seq/data/mash_output_vietnam_6461_v2
```

4. **Assessment**

The mash screen outputs will contain a score over 1000 on similarity with references. If you do not get any scores or very few scores above 990, then you may need to consider using a better reference before proceeding.

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
    /data/pam/team284/shared/deep_seq/data/combined_vietnam_ref.fna \
    /data/pam/team284/shared/deep_seq/data/themisto_index_vietnam_ref
```

2. **Run themisto align and mSWEEP**

You will also need:
- Seroba database
- GPSC assignment external clusters csv for your reference lanes (from popPUNK)

```
./run_msweep_pipeline.sh \
    <path to reference assembly files> \
    <path to input fastq files> \
    <reference fna> \
    <themisto index> \
    <gpsc assignment csv> \
    <seroba database> \
    <msweep output directory>
```

For example:

```
./run_msweep_pipeline.sh \
    /data/pam/team284/shared/deep_seq/data/ref_assemblies \
    /data/pam/team284/shared/deep_seq/data/input_fastqs \
    /data/pam/team284/shared/deep_seq/data/combined_vietnam_ref.fna \
    /data/pam/team284/shared/deep_seq/data/themisto_index_vietnam_ref \
    /data/pam/team284/shared/deep_seq/data/GPSC_assignment_external_clusters.csv \
    /nfs/users/nfs_g/gt4/lustre/maela_deep/msweep/seroba/database \
    /data/pam/team284/shared/deep_seq/data/msweep_output_v2/6461
```

## Outputs from pipeline

The output files can be found in study folders within the msweep output directory you specified above. Each output is separated in directories called by the lane id of the deep sequence and number of reads that they were subsampled to and contain:

- `mSWEEP_abundances.txt`: the relative proportion of GPSCs
- `seroba_calls.tab`: the serotypes found
- `fastq.gz` files: the reads that have been identified belonging to a particular GPSC
- directories named after the GPSC number: contain the assemblies of the GPSCs as `contigs.fa` and the serotype in `*_seroba` directory _(Note: NA may exist if there were alignments to isolate genome(s) that had no GPSC)_

## Build phylogenetic trees from output deconvoluted reads

Create phylogenetic trees from deconvoluted reads [using snippy, gubbins, snp-sites and FastTree](https://github.com/tseemann/snippy)

In the scripts directory:
```
# Create an input.txt file for snippy
find /data/pam/team284/shared/deep_seq/data/msweep_output/6461/*/ /data/pam/team284/shared/deep_seq/data/msweep_output/6463/*/ -type f -name "*_1.fastq.gz" > ../data/path_to_reads_1.txt
find /data/pam/team284/shared/deep_seq/data/msweep_output/6461/*/ /data/pam/team284/shared/deep_seq/data/msweep_output/6463/*/ -type f -name "*_2.fastq.gz" > ../data/path_to_reads_2.txt
cat ../data/path_to_reads_1.txt | awk -F/ '{print $12"_"$13}' | awk -F'_1.fastq.gz' '{print $1}' > ../data/msweep_samples.txt
paste -d $'\t' ../data/msweep_samples.txt ../data/path_to_reads_1.txt ../data/path_to_reads_2.txt | grep -v "_NA" > ../data/snippy_input.tab

# Build trees (tested with 10)
head ../data/snippy_input.tab > ../data/snippy_input_head.tab
bsub -G team284 -q normal -J build_tree -o ../log/build_tree.out -e ../log/build_tree.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 -n 4 "./run_build_trees.sh /data/pam/team284/shared/deep_seq/data/snippy_input_head.tab /data/pam/applications/vr-pipelines/refs/Streptococcus/pneumoniae_ATCC_700669/Streptococcus_pneumoniae_ATCC_700669_v1.fa 4 ../data/test_build_tree"

# Build trees (not implemented)
bsub -G team284 -q normal -J build_tree -o ../log/build_tree.out -e ../log/build_tree.err -R"span[hosts=1]" -R "select[mem>64000] rusage[mem=64000]" -M64000 -n 16 "./run_build_trees.sh /data/pam/team284/shared/deep_seq/data/snippy_input.tab /data/pam/applications/vr-pipelines/refs/Streptococcus/pneumoniae_ATCC_700669/Streptococcus_pneumoniae_ATCC_700669_v1.fa 16 <your_output_directory_here>"
```

