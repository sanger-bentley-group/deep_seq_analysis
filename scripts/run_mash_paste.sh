#!/usr/bin/env bash

dir=$1
output_mash_file=$2

module load mash/2.1.1--he518ae8_0

mkdir -p ../log

mash paste $output_mash_file ${dir}/*.msh 
