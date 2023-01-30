#!/usr/bin/env bash

lanes_file=../data/gps_vietnam_lanes.txt
threads=1
dir=../data/assemblyfind_gps_vietnam_lanes.txt

module load mash/2.1.1--he518ae8_0

mkdir -p ../log
mkdir -p ../data/mash_sketches_gps_vietnam
num=$(cat ${lanes_file} | wc -l)

for ((i=1;i<=${num};i++))
do
    lane=$(sed -n "${i}p" ${lanes_file})
    if [ ! -f ../data/mash_sketches_gps_vietnam/${lane}.msh ]
    then
        bsub -G team284 -J mash_sketch_${i} -o ../log/mash_sketch_${i}.out -e ../log/mash_sketch_${i}.err -n ${threads} -R"span[hosts=1]" -R "select[mem>8000] rusage[mem=8000]" -M8000 "mash sketch -r -o ../data/mash_sketches_gps_vietnam/${lane}.msh ${dir}/${lane}.contigs_velvet.fa -p ${threads}"
    fi
done