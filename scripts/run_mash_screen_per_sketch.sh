#!/usr/bin/env bash

read1=$1
read2=$2
groups=$3
threads=$4

mash_sketch_file="../data/mash_sketches.txt"

module load mash/2.1.1--he518ae8_0

mkdir -p ../log

if [ ! -f ${mash_sketch_file} ]
then
    ls ../data/mash_sketches > ${mash_sketch_file}
fi
num=$(cat ${mash_sketch_file} | wc -l)
num=1

for ((i=1;i<=${num};i++))
do
    mash_sketch=$(sed -n "${i}p" ${mash_sketch_file})
    gps_name=$(echo ${mash_sketch} | cut -f1 -d.)
    echo ${gps_name}
    
    mkdir -p ../data/mash_output/${gps_name}
    grep ${gps_name} ${groups} > ../data/${gps_name}_groups.tab
    
    python3 run_mash_screen_on_gpsc.py --r1 ${read1} --r2 ${read2} --s ../data/mash_sketches/${mash_sketch} --g ../data/${gps_name}_groups.tab -t ${threads} -o ../data/mash_output/${gps_name}
    
    #rm ../data/${gps_name}_groups.tab
done
