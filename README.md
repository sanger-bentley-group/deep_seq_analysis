# Deep Sequencing Pipeline for _Streptococcus Pneumoniae_ within-host diversity in Vietnam

_Author: Victoria Dyster_

_Credits:_

- _Adapted from Gerry Tonkin-Hill's [pipeline](https://www.nature.com/articles/s41564-022-01238-1)_

- _Ana Ferreira for running the QC and PopPUNK to get GPSCs for the isolates_

- _Gemma Murray for help getting started_

## Get symlinks of all isolate assemblies

```
module load pf
cd /nfs/users/nfs_v/vc11/scratch/DATABASES/lays_isolates/data
pf assembly -i /nfs/users/nfs_v/vc11/scratch/DATABASES/lays_isolates/lanes.txt -t file -l
```

## Set working directory

```
cd /nfs/users/nfs_v/vc11/scratch/DATABASES/lays_isolates/scripts
```

## Find similarity of deep sequences to isolate assemblies

1. Create mash sketch (i.e. reference) for each Vietnam isolate assembly (uses all lanes)

```
./run_mash_sketch.sh /nfs/users/nfs_v/vc11/scratch/DATABASES/lays_isolates/lanes.txt
```

2. Run mash paste (i.e. combine mash references)

```
bsub -G team284 -q normal -J mash_paste -o ../log/mash_paste.out -e ../log/mash_paste.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_mash_paste.sh'
```

3. Run mash screen for study 6461 (i.e. align deep sequences from study 6461 against mash reference)

```
bsub -G team284 -q normal -J mash_screen -o ../log/mash_screen_6461.out -e ../log/mash_screen_6461.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_mash_screen.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_6461.txt /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/mash_output_vietnam_6461'
```

4. Run mash screen for study 6463 (i.e. align deep sequences from study 6463 against mash reference)

```
bsub -G team284 -q normal -J mash_screen -o ../log/mash_screen_6463.out -e ../log/mash_screen_6463.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_mash_screen.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_6463.txt /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/mash_output_vietnam_6463'
```

## Run mSWEEP Pipeline

1. Subsample to 1 million reads for each deep sequenced sample (for low storage size alignments) for:

- study 6461

```
bsub -G team284 -q normal -J seqtk -o ../log/seqtk_6461.out -e ../log/seqtk_6461.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_seqtk.sh 6461 /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_6461.txt'
```

- study 6463

```
bsub -G team284 -q normal -J seqtk -o ../log/seqtk_6463.out -e ../log/seqtk_6463.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_seqtk.sh 6463 /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_6463.txt'
```

2. Combine isolate assemblies to make one reference FASTA (only lanes that have passed QC\*)

```
bsub -G team284 -q normal -J combine_fastas -o ../log/combine_fastas.out -e ../log/combine_fastas.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_combine_fastas.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/lanes_passed.txt /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/assemblyfind_lanes.txt'
```

3. Build Themisto index on this reference

```
./run_themisto_build.sh /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/combined_vietnam.fna /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/themisto_index_vietnam
```

4. Run themisto align and mSWEEP for:

- study 6461

```
./run_msweep_pipeline.sh 6461 /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/sampled_reads/6461
```

- study 6463

```
./run_msweep_pipeline.sh 6463 /nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/sampled_reads/6463
```

_\*Run by Ana Ferreira_

## Outputs from pipeline

The output files can be found in study folders within `/nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/msweep_output`. Each output is separated in directories called by the lane id of the deep sequence and number of reads that they were subsampled to and contain:

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

