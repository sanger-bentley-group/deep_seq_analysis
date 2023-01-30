#!/usr/bin/env bash

dir=../data/mash_sketches_gps_vietnam

module load mash/2.1.1--he518ae8_0

mkdir -p ../log

mash paste ../data/gps_vietnam_combined.msh ${dir}/*.msh 
