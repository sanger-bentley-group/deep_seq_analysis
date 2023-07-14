#!/usr/bin/env bash

reference=$1
index_prefix=$2

module load themisto/2.1.0

mkdir -p ${index_prefix}
mkdir -p ${index_prefix}/tmp

bsub -G team284 -n8 -M64000 -R"span[hosts=1]" -R"select[mem>64000] rusage[mem=64000]" -q long -J themisto_build -o ../log/themisto_build.out -e ../log/themisto_build.err "themisto build -k 31 -i ${reference} -o ${index_prefix} --temp-dir ${index_prefix}/tmp --mem-megas 64000 --n-threads 8"