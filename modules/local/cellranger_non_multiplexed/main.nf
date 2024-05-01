
process CELLRANGER_NON_MULTIPLEXED {
    time '96h'
    cpus 16
    memory '160 GB'
    label 'process_high'

  input:
    val(mode)
    path(reference)
    path(vdj_reference)
    path(gex_fastq, stageAs: "?/GEX/*")
    val(gex_id)
    path(meta_yaml)
    val(sample_id)
    path(cite_fastq, stageAs: "?/CITE/*")
    val(cite_id)
    path(bcr_fastq, stageAs: "?/BCR/*")
    val(bcr_id)
    path(tcr_fastq, stageAs: "?/TCR/*")
    val(tcr_id)
  output:
    path("demultiplex_output/"), emit: cellranger_output
  script:
    def cite_fastq_opt = cite_id != 'NODATA' ? " --cite_fastq ${cite_fastq}" : ''
    def cite_id_opt = cite_id != 'NODATA' ? " --cite_id ${cite_id}" : ''
    def tcr_fastq_opt = tcr_id != 'NODATA' ? " --tcr_fastq ${tcr_fastq}" : ''
    def tcr_id_opt = tcr_id != 'NODATA' ? " --tcr_id ${tcr_id}" : ''
    def bcr_fastq_opt = bcr_id != 'NODATA' ? " --bcr_fastq ${bcr_fastq}" : ''
    def bcr_id_opt = bcr_id != 'NODATA' ? " --bcr_id ${bcr_id}" : ''

    """
        cellranger_utils cellranger-nonmultiplexed \
        --reference $reference \
        --vdj_reference $vdj_reference \
        --meta_yaml $meta_yaml \
        --gex_fastq $gex_fastq \
        --gex_id $gex_id \
        --outdir demultiplex_output \
        --tempdir temp \
        --numcores ${task.cpus} \
        --mempercore 10 \
        --sample_id $sample_id \
        $cite_fastq_opt $cite_id_opt \
        $bcr_fastq_opt $bcr_id_opt \
        $tcr_fastq_opt $tcr_id_opt \
    """
  stub:
    """
    mkdir -p demultiplex_output/
    mkdir -p demultiplex_output/
    """
}
