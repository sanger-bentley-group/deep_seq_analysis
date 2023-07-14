#!/usr/bin/env bash

# options
lanes_file=$1
ref_lanes_file=$2
reference_fna=$3
reference_index=$4
gpsc_assignment=$5
seroba_db=$6
outdir=$7

# modules
module load pf
module load shovill/1.1.0--0
module load seroba/1.0.0=py36_1-c1
module load themisto/2.1.0
module load mgems/1.3.1--h468198e_0
module load msweep/2.0.0
module load alignment-writer/0.4.0

# setup
mkdir -p ${outdir}
mkdir -p ../log

# Get read file names
num_reads=$(cat ${lanes_file} | wc -l)

# Get number of reference sequences
ref_num=$(grep "^>" $reference_fna | wc -l)

# Create col group file from GPSC assignment
col_group_file=${outdir}/col_groups.txt
ref_lane_num=$(cat ${ref_lanes_file} | wc -l)

if [ -f $col_group_file ]
then
    rm $col_group_file
fi

for ((i=1;i<=${ref_lane_num};i++))
do
    lane=$(sed -n "${i}p" ${ref_lanes_file})
    group=$(grep ${lane}, $gpsc_assignment | cut -f2 -d,)
    echo $group >> ${outdir}/themisto >> $col_group_file
done

# Run msweep pipeline for each read file
for ((i=1;i<=${num_reads};i++))
do
    lane=$(sed -n "${i}p" ${lanes_file})
    reads_dir=$(pf data -t lane -i ${lane})
    
    line_num=$(zcat ${reads_dir}/${lane}_1.fastq.gz | wc -l)
    read_num=$(( line_num / 4 ))
    
    bsub -G team284 -n8 -M64000 -R"span[hosts=1]" -R"select[mem>64000] rusage[mem=64000]" -q long -o ../log/msweep_${i}.out -e ../log/msweep_${i}.err "python3 run_mSWEEP_pipeline.py --r1 ${reads_dir}/${lane}_1.fastq.gz --r2 ${reads_dir}/${lane}_2.fastq.gz --index ${reference_index} -n ${ref_num} -r ${read_num} --group_column ${col_group_file} --seroba_db ${seroba_db} -o ${outdir} -t 8 --mem 64000"
    
done
