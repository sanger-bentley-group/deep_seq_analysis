#!/usr/bin/env bash

module load snippy/4.6.0
module load gubbins/3.2.1
module load snp-sites/2.5.1--hed695b0_0
module load fasttree/2.1.10=h470a237_2-c1

snippy_input=$1
reference=$2
cpus=$3
output_dir=$4

mkdir -p ${output_dir}
cd ${output_dir}

snippy-multi $snippy_input --ref $reference --cpus $cpus > runme.sh
sh runme.sh
snippy-clean_full_aln core.full.aln > clean.full.aln
run_gubbins.py -p gubbins clean.full.aln
snp-sites -c gubbins.filtered_polymorphic_sites.fasta > clean.core.aln
FastTree -gtr -nt clean.core.aln > clean.core.tree