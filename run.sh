module load samtools
module load java/jdk-11.0.11
module load singularity/3.7.1

rm -rf .nextflow.log* work && ./nextflow run phasing_from_bam.nf -with-singularity /juno/work/shah/mondrian/singularity/haplotype_grch38_v0.0.69.sif -resume -params-file params_bam.yaml


rm -rf .nextflow.log* work && ./nextflow run phasing_from_vcf.nf -with-singularity /juno/work/shah/mondrian/singularity/haplotype_grch38_v0.0.69.sif -resume -params-file params_vcf.yaml
