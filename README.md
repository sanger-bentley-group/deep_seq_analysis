# Run mash, read subsampling and the mSWEEP pipeline on Sanger farm
```
cd ../scripts
```

## Create mash sketch for each GPS reference
```
./run_mash_sketch.sh
```

## Run mash paste
Combines all mash sketches into one
```
bsub -G team284 -q normal -J mash_paste -o ../log/mash_paste.out -e ../log/mash_paste.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 './run_mash_paste.sh'
```

## Run mash screen for study 6463
```
./run_mash_screen.sh ../data/lanes_6463.txt ../data/mash_output_6463
```

## Run mash screen for study 6461
```
./run_mash_screen.sh ../data/lanes_6461.txt ../data/mash_output_6461
```

## Subsample reads (for 4 samples)
```
./run_seqtk.sh 6461 ../data/lanes_6461_4.txt
```

## Combine GPS reference fastas
```
bsub -G team284 -q normal -J combine_fastas -o ../log/combine_fastas.out -e ../log/combine_fastas.err -R"span[hosts=1]" -R "select[mem>16000] rusage[mem=16000]" -M16000 'cat ../data/assemblyfind_gps_vietnam_lanes.txt/*.fa > ../data/combined_vietnam_fasta.fa'
```

## Run the mSWEEP pipeline
```
./run_msweep_pipeline.sh 6461 ../data/sampled_reads/6461
```