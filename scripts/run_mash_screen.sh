#!/usr/bin/env bash

reads_dir=$1
reference=$2
mash_output_dir=$3
threads=4

module load mash/2.1.1--he518ae8_0

mkdir -p ${mash_output_dir}

for fastq in ${reads_dir}/*_1.fastq.gz
do
    sample=$(realpath ${fastq} | awk -F "/" '{ print $NF }' | awk -F "." '{ print $1 }' | rev | sed 's|1_||' | rev)
    bsub -J mash_screen_${sample} -o ../log/mash_screen_${sample}.out -e ../log/mash_screen_${sample}.err -n ${threads} -R"span[hosts=1]" -R "select[mem>1000] rusage[mem=1000]" -M1000 "python3 run_mash_screen.py --t ${threads} --s ${reference} --r1 ${reads_dir}/${sample}_1.fastq.gz  --r2 ${reads_dir}/${sample}_2.fastq.gz --o ${mash_output_dir}"
done