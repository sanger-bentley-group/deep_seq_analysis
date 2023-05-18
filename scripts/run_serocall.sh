#!/usr/bin/env bash

study=$1
serocall_output_dir=$2
threads=4

module load pf/1.1.1
module load bwa/0.7.17-r1188
module load samtools/1.9--h91753b0_8

serocall=/nfs/users/nfs_v/vc11/lustre/ANALYSIS/deep_seq/SeroCall/serocall

mkdir -p ../log
mkdir -p ${serocall_output_dir}

pf info -t study -i ${study} | sed '1d' | cut -f1 -d' ' > ../data/lanes_${study}.txt

num=$(cat ../data/lanes_${study}.txt | wc -l)

for ((i=1;i<=${num};i++))
do
    lane=$(sed -n "${i}p" ${lanes_file})
    if [ ! -f ${serocall_output_dir}/${lane}_calls.txt ]
    then
        data_dir=$(pf data -t lane -i ${lane})
        bsub -G team284 -J serocall_${i} -o ../log/serocall_${i}.out -e ../log/serocall_${i}.err -n ${threads} -R"span[hosts=1]" -R "select[mem>8000] rusage[mem=8000]" -M8000 "${serocall} -o ${serocall_output_dir}/${lane} -t ${threads} ${data_dir}/${lane}_1.fastq.gz ${data_dir}/${lane}_2.fastq.gz"
    fi
done
