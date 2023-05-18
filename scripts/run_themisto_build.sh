#!/usr/bin/env bash

reference=$1
index_prefix=$2
themisto_build=/nfs/users/nfs_g/gt4/lustre/maela_deep/msweep/Themisto/build/bin/build_index
temp=../data/themisto_temp

mkdir -p ${index_prefix}
mkdir -p ${temp}
rm -rf ${index_prefix}/*
rm -rf ${temp}/*

bsub -G team284 -n8 -M64000 -R"span[hosts=1]" -R"select[mem>64000] rusage[mem=64000]" -q long -J themisto_build -o ../log/themisto_build.out -e ../log/themisto_build.err "${themisto_build} --k 31 --input-file ${reference}  --auto-colors --index-dir ${index_prefix} --temp-dir ${temp} --mem-megas 64000 --n-threads 8"
