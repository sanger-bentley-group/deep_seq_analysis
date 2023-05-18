#!/usr/bin/env bash

study=$1
lanes_file=$2

dir=../data/sampled_reads/${study}
mkdir -p ${dir}

module load seqtk/1.3--ha92aebf_0
module load pf/1.1.1

mkdir -p ../log

num_lanes=$(cat ${lanes_file} | wc -l)

for ((i=1;i<=${num_lanes};i++))
do
    lane=$(sed -n "${i}p" ${lanes_file})
    reads_dir=$(pf data -t lane -i ${lane})
    bsub -G team284 -J seqtk_${i} -o ../log/seqtk_${i}.out -e ../log/seqtk_${i}.err -R"span[hosts=1]" -R "select[mem>64000] rusage[mem=64000]" -M64000 "seqtk sample -s1 ${reads_dir}/${lane}_1.fastq.gz 1000000 > ${dir}/${lane}_1000000_1.fastq && seqtk sample -s1 ${reads_dir}/${lane}_2.fastq.gz 1000000 > ${dir}/${lane}_1000000_2.fastq && gzip ${dir}/${lane}_1000000_*.fastq"
done