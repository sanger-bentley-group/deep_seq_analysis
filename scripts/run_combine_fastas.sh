#!/usr/bin/env bash

assemblies_dir=$1
combined_file=$2


if [ -f ${combined_file} ]
then
    rm ${combined_file}
fi


for assembly in ${assemblies_dir}/*.fa
do
    sample=$(realpath -s ${assembly} | awk -F "/" '{ print $NF }' | awk -F "." '{ print $1 }')
    echo ">${sample/\#/\_}" >> ${combined_file}
    sed '/>/d' ${assembly} >> ${combined_file}
done