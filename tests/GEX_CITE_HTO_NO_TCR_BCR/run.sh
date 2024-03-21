module load java/jdk-11.0.11
module load singularity/3.7.1

../nextflow pull shahcompbio/scrna_demultiplexing -r master

../nextflow run shahcompbio/scrna_demultiplexing -r master -resume -with-singularity $PWD/../cellranger.sif  -profile singularity --output_dir outputs --jobmode local --numcores 16 --meta_yaml $PWD/meta.yaml  --gex_fastq $PWD/../10x_test_data/gex  --gex_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_gex --cite_fastq $PWD/../10x_test_data/cite --cite_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_ab --reference $PWD/../reference_grch38_scrna/GRCh38/ --vdj_reference $PWD/../reference_grch38_scrna/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0 --sample_id SA123 --bcr_fastq $PWD/../10x_test_data/cite --bcr_id PBMC-ALL_60k_universal_HashAB1-4_BL_4tags_Rep1_ab
