# scrna demultiplexing workflow



## Quickstart

1. Download test dataset
```
wget https://mondriantestdata.s3.amazonaws.com/10x_test_data.tar.gz
tar -xvf 10x_test_data.tar.gz
```
2. Download reference datasets. 
```
wget https://mondriantestdata.s3.amazonaws.com/reference_grch38_scrna.tar.gz
tar -xvf reference_grch38_scrna.tar.gz
```

3. Launch pipeline
```
nextflow run shahcompbio/scrna_demultiplexing \
  -profile singularity \
  --output_dir outputs \
  --jobmode local \
  --numcores 16 \
  --meta_yaml 10x_test_data/meta.yaml \
  --gex_fastq 10x_test_data/gex  \
  --gex_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_gex \
  --cite_fastq 10x_test_data/cite \
  --cite_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_ab \
  --reference reference_grch38_scrna/GRCh38/ \
  --vdj_reference reference_grch38_scrna/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
  --sample_id SAMP123 \
  --bcr_fastq 10x_test_data/cite \
  --bcr_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_ab
```



## Workflow use cases


| Gene Expression        | Cite Seq               | HTO                    | VDJ-B                  | VDJ-T                  | Steps          | Testing             |
|------------------------|------------------------|------------------------|------------------------|------------------------|----------------|---------------------|
|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_multiplication_x:|:heavy_multiplication_x:|:heavy_multiplication_x:|NonMultiplex    | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_multiplication_x:|DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_multiplication_x:|:heavy_multiplication_x:|NonMultiplex    | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |:heavy_multiplication_x:|NonMultiplex    | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_multiplication_x:|:heavy_check_mark:      |NonMultiplex    | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |:heavy_check_mark:      |NonMultiplex    | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_multiplication_x:|DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |:heavy_multiplication_x:|:heavy_check_mark:      |DeMultiplex     | :heavy_check_mark:  |
|:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |:heavy_check_mark:      |DeMultiplex     | :heavy_check_mark:  |

Logic can be summed up with this pseudocode
```
if HTO:
    CELLRANGERMULTI(gex_fastq, cite_fastq)   -> {raw_h5, [['sample': filtered_h5, bam], ...]}
    for sample in CELLRANGERMULTI:
      BAM2FASTQ(sample.bam)
      CELLRANGERMULTI(bam2fastq.gex_fastq, cite_fastq,vdj_b_fastq, vdj_t_fastq) -> {raw_h5, ['sample': filtered_h5, bam]}
      CELLBENDER(CELLRANGERMULTI.raw_h5)
else:
    CELLRANGERMULTI(gex_fastq, cite_fastq,vdj_b_fastq, vdj_t_fastq) -> {raw_h5, ['sample': filtered_h5, bam]}
    CELLBENDER(CELLRANGERMULTI.raw_h5)    
```
