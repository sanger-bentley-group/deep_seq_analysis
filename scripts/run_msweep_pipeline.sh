#!/usr/bin/env bash

# options
ref_input_dir=$1
input_dir=$2
reference_fna=$3
reference_index=$4
gpsc_assignment=$5
seroba_db=$6
outdir=$7

# modules
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
#num_reads=$(cat ${lanes_file} | wc -l)

# Get number of reference sequences
ref_num=$(grep "^>" $reference_fna | wc -l)

# Create col group file from GPSC assignment
col_group_file=${outdir}/col_groups.txt


if [ -f $col_group_file ]
then
    rm $col_group_file
fi

for assembly in ${ref_input_dir}/*.fa
do
    sample=$(realpath -s ${assembly} | awk -F "/" '{ print $NF }' | awk -F "." '{ print $1 }')
    group=$(grep ${sample}, $gpsc_assignment | cut -f2 -d, | sed 's/;/or/')
    echo $group >> $col_group_file
done

# Run msweep pipeline for each read file
for fastq in ${input_dir}/*_1.fastq.gz
do
    sample=$(realpath -s ${fastq} | awk -F "/" '{ print $NF }' | awk -F "." '{ print $1 }' | rev | sed 's|1_||' | rev)

    line_num=$(zcat ${input_dir}/${sample}_1.fastq.gz | wc -l)
    read_num=$(( line_num / 4 ))

    bsub -n8 -M64000 -R"span[hosts=1]" -R"select[mem>64000] rusage[mem=64000]" -q long -o ../log/msweep_${sample}.out -e ../log/msweep_${sample}.err "python3 run_mSWEEP_pipeline.py --r1 ${input_dir}/${sample}_1.fastq.gz --r2 ${input_dir}/${sample}_2.fastq.gz --index ${reference_index} -n ${ref_num} -r ${read_num} --group_column ${col_group_file} --seroba_db ${seroba_db} -o ${outdir} -t 8 --mem 64000"

done
