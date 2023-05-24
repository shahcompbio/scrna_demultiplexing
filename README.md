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
  --output_dir outputs \
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