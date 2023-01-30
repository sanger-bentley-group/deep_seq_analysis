#!/usr/bin/env bash

lanes_file=$1
mash_output_dir=$2
reference=../data/gps_vietnam_combined.msh
#gpsc=../data/GPS_v6_external_clusters.csv
#groups=../data/gps_v6_groups.tab
threads=4

module load pf/1.1.1
module load mash/2.1.1--he518ae8_0

# Create GPS group table
#cat ${gpsc} | sed 1d | sed 's/,/\t/' > ${groups}

mkdir -p ../log
mkdir -p ${mash_output_dir}
num=$(cat ${lanes_file} | wc -l)

for ((i=1;i<=${num};i++))
do
    lane=$(sed -n "${i}p" ${lanes_file})
    rm -r ${mash_output_dir}/${lane}
    data_dir=$(pf data -t lane -i ${lane})
    bsub -G team284 -J mash_screen_${i} -o ../log/mash_screen_${i}.out -e ../log/mash_screen_${i}.err -n ${threads} -R"span[hosts=1]" -R "select[mem>8000] rusage[mem=8000]" -M8000 "python3 run_mash_screen_on_gpsc.py --t ${threads} --s ${reference} --r1 ${data_dir}/${lane}_1.fastq.gz  --r2 ${data_dir}/${lane}_2.fastq.gz --o ${mash_output_dir}"

done