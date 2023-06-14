# scrna demultiplexing workflow




docker container:
```
quay.io/diljotgrewal/cellranger

```



to run with LSF + singularity

```
singularity build cellranger.sif docker://quay.io/diljotgrewal/cellranger

nextflow run shahcompbio/scrna_demultiplexing \
  --output_dir outputs \
  -profile lsf,singularity \
  -with-singularity /path/to/cellranger.sif \
  --meta_yaml /path/to/meta.yaml \
  --reference /juno/work/shah/reference/transcriptomes/GRCh38 \
  --vdj_reference /juno/work/shah/reference/transcriptomes/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
  --gex_fastq /path/to/GEX/ \
  --gex_id GEX_bamtofastq \
  --cite_fastq /path/to/CITE/ \
  --cite_id CITE_bamtofastq \
  -resume \
  --jobmode local
```




to run with LSF only:

create nextflow.config file
```
process {
        withLabel: 'cellranger' {
           memory='12G'
           cpus='2'
       }
}
```


```
export PATH=/juno/work/shah/software/cellranger-7.1.0/bin/:$PATH
export PATH=/juno/work/shah/software/cellranger-7.1.0/lib/bin/:$PATH

nextflow run shahcompbio/scrna_demultiplexing \
  - \
  -profile lsf \
  --meta_yaml /path/to/meta.yaml \
  --reference /juno/work/shah/reference/transcriptomes/GRCh38 \
  --vdj_reference /juno/work/shah/reference/transcriptomes/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 \
  --gex_fastq /path/to/GEX/ \
  --gex_id GEX_bamtofastq \
  --cite_fastq /path/to/CITE/ \
  --cite_id CITE_bamtofastq \
  -resume \
  --jobmode lsf
```









## Test data

1. Download Test dataset
    ```
    wget https://mondriantestdata.s3.amazonaws.com/10x_test_data.tar.gz
    tar -xvf 10x_test_data.tar.gz
    ```

2. Install Nextflow


3. launch pipeline:

3.1 to run on juno with singularity

build container
```
module load singularity/3.7.1
singularity build cellranger.sif docker://quay.io/diljotgrewal/cellranger
```

launch pipeline
```
module load java/jdk-11.0.11
nextflow run shahcompbio/scrna_demultiplexing \
-resume \
-with-singularity $PWD/cellranger.sif  \
-profile singularity \
--output_dir outputs \
--jobmode local \
--numcores 16 \
--meta_yaml $PWD/10x_test_data/meta.yaml  \
--gex_fastq $PWD/10x_test_data/gex \
--cite_fastq $PWD/10x_test_data/cite  \
--gex_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_gex \
--cite_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_ab \
--reference /juno/work/shah/reference/transcriptomes/GRCh38 \
--vdj_reference /juno/work/shah/reference/transcriptomes/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0
```
