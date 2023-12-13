#!/usr/bin/env bash

mash_sketch_dir=$1
output_mash_file=$2

module load mash/2.1.1--he518ae8_0

mash paste $output_mash_file ${mash_sketch_dir}/*.msh
