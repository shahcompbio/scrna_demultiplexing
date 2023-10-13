process CELLRANGER_DEMULTIPLEX {
    time '96h'
    cpus 16
    memory '12 GB'
    label 'cellranger'

  input:
    path(reference)
    path(meta_yaml)
    path(gex_fastq, stageAs: "?/GEX/*")
    val(gex_id)
    path(cite_hto_fastq, stageAs: "?/CITE/*")
    val(cite_hto_id)
    val(sample_id)
  output:
    path("demultiplex_output/"), emit: demultiplexed_output
  script:
    def cite_hto_fastq_opt = cite_hto_id != 'NODATA' ? " --cite_hto_fastq ${cite_hto_fastq}" : ''
    def cite_hto_id_opt = cite_hto_id != 'NODATA' ? " --cite_hto_id ${cite_hto_id}" : ''
    """
        cellranger_utils cellranger-demultiplex \
        --reference $reference \
        --meta_yaml $meta_yaml \
        --gex_fastq $gex_fastq \
        --gex_id $gex_id \
        --outdir demultiplex_output \
        --tempdir temp \
        --numcores ${task.cpus} \
        --mempercore 10 \
        --sample_id ${sample_id} \
        $cite_hto_fastq_opt $cite_hto_id_opt \

    """
  stub:
    """
    mkdir -p demultiplex_output/outs/per_sample_outs/
    mkdir -p demultiplex_output/outs/per_sample_outs/
    """
}
