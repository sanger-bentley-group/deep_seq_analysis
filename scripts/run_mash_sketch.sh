#!/usr/bin/env bash

assemblies_dir=$1
output_dir=$2
threads=1

module load mash/2.1.1--he518ae8_0

mkdir -p ../log
mkdir -p ${output_dir}

for assembly in ${assemblies_dir}/*.fa
do
    sample=$(realpath ${assembly} | awk -F "/" '{ print $NF }' | awk -F "." '{ print $1 }')
    if [ ! -f ${output_dir}/${lane}.msh ]
    then
        bsub -J mash_sketch_${sample} -o ../log/mash_sketch_${sample}.out -e ../log/mash_sketch_${sample}.err -n ${threads} -R"span[hosts=1]" -R "select[mem>1000] rusage[mem=1000]" -M1000 "mash sketch -r -o ${output_dir}/${sample}.msh ${assembly} -p ${threads}"
    fi
done