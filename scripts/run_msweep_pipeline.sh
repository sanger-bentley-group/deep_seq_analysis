#!/usr/bin/env bash

study=$1
dir=$2

module load shovill/1.1.0--0
module load seroba/1.0.0=py36_1-c1

msweep_output=../data/msweep_output
mkdir -p ${msweep_output}
outdir=${msweep_output}/${study}
mkdir -p ${outdir}
mkdir -p ../log

ls ${dir}/*_1.fastq.gz | awk -F'_1.fastq.gz' '{print $1}' | awk -F'/' '{print $NF}' > ../data/read_names_${study}.txt
num_reads=$(cat ../data/read_names_${study}.txt | wc -l)

for ((i=1;i<=${num_reads};i++))
do
    name=$(sed -n "${i}p" ../data/read_names_${study}.txt)
    
    bsub -G team284 -n8 -M64000 -R"span[hosts=1]" -R"select[mem>64000] rusage[mem=64000]" -q long -o ../log/msweep_${study}_${i}.out -e ../log/msweep_${study}_${i}.err "python3 run_mSWEEP_pipeline.py --r1 ${dir}/${name}_1.fastq.gz --r2 ${dir}/${name}_2.fastq.gz -o ${outdir} -t 8 --mem 64000"
done
