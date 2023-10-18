module load java/jdk-11.0.11
module load singularity/3.7.1

../nextflow pull shahcompbio/scrna_demultiplexing -r newrefactor

../nextflow run shahcompbio/scrna_demultiplexing -r newrefactor -resume -with-singularity $PWD/../cellranger.sif  -profile lsf,singularity --output_dir outputs --jobmode local --numcores 16 --meta_yaml $PWD/meta.yaml  --gex_fastq $PWD/../data/gex  --gex_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_gex --cite_fastq $PWD/../data/cite --cite_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_ab --reference /juno/work/shah/reference/transcriptomes/GRCh38 --vdj_reference /juno/work/shah/reference/transcriptomes/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 --sample_id SA123
