#!/usr/bin/env bash

lanes_file=$1
assemblies_dir=$2
combined_file=/nfs/users/nfs_v/vc11/scratch/ANALYSIS/deep_seq/data/combined_vietnam.fna

rm ${combined_file}
num=$(cat ${lanes_file} | wc -l)

for ((i=1;i<=${num};i++))
do 
    lane=$(sed -n "${i}p" ${lanes_file})
    echo ">${lane/\#/\_}" >> ${combined_file}
    sed '/>/d' ${assemblies_dir}/${lane}.contigs_velvet.fa >> ${combined_file}
done