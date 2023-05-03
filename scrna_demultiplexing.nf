// Declare syntax version
nextflow.enable.dsl=2

process Demultiplex {
    time '96h'
    cpus 1
    memory '10 GB'

  input:
    path(reference)
    path(meta_yaml)
    path(gex_fastq, stageAs: "?/GEX/*")
    val(gex_id)
    path(cite_fastq, stageAs: "?/CITE/*")
    val(cite_id)
  output:
    path("demultiplex_output/*"), emit: per_sample_data
    path("demultiplexing.tar"), emit: tar_output
  script:
    """
        scrna_demultiplexing_utils cellranger-multi \
        --reference $reference \
        --meta_yaml $meta_yaml \
        --gex_fastq $gex_fastq \
        --gex_id $gex_id \
        --cite_fastq $cite_fastq \
        --cite_id $cite_id \
        --outdir demultiplex_output \
        --tempdir temp \
        --tar_output demultiplexing.tar \
        --numcores 16 \
        --mempercore 10 \
        --jobmode lsf \
        --maxjobs 2000
    """
}

process BamToFastq{
    time '96h'
    cpus 1
    memory '10 GB'

    input:
        path(per_sample_data)
    output:
        tuple(val(sample_id), path("output"), path("${per_sample_data}/*metrics_summary.csv"))
    script:
        sample_id = "${per_sample_data.baseName}"
        """
            scrna_demultiplexing_utils bam-to-fastq \
              --bam_file $per_sample_data/*bam \
              --metrics $per_sample_data/*metrics_summary.csv \
              --outdir output \
              --tempdir temp
        """
}


process CellRangerMultiVdj{
    time '96h'
    cpus 1
    memory '10 GB'

    input:
        tuple(
            val(sample_id),
            path(gex_fastq, stageAs: "?/GEX/*"),
            path(gex_metrics),
            path(tcr_fastq, stageAs: "?/TCR/*"),
            val(tcr_id),
            path(bcr_fastq, stageAs: "?/BCR/*"),
            val(bcr_id),
            path(cite_fastq, stageAs: "?/CITE/*"),
            val(cite_id),
            path(reference),
            path(feature_reference),
            path(vdj_reference)
        )
    output:
        path("${sample_id}_vdj.tar"), emit: tar_output
    script:
        def bcr_fastq_opt = bcr_id != 'NODATA' ? " --bcr_fastq ${bcr_fastq}" : ''
        def bcr_id_opt = bcr_id != 'NODATA' ? " --bcr_id ${bcr_id}" : ''
        """
            scrna_demultiplexing_utils  cellranger-multi-vdj \
            --reference $reference \
            --feature_reference $feature_reference \
            --vdj_reference $vdj_reference \
            --gex_fastq $gex_fastq \
            --gex_id bamtofastq \
            --gex_metrics $gex_metrics \
            --tcr_fastq $tcr_fastq \
            --tcr_id $tcr_id \
            --cite_fastq $cite_fastq \
            --cite_id $cite_id \
            --tar_output ${sample_id}_vdj.tar \
            --tempdir temp \
            --numcores 16 \
            --mempercore 10 \
            --jobmode lsf \
            --maxjobs 2000 \
            $bcr_fastq_opt $bcr_id_opt
        """
}


workflow{
    reference = Channel.fromPath(params.reference)
    feature_reference = Channel.fromPath(params.feature_reference)
    vdj_reference = Channel.fromPath(params.vdj_reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)
    gex_fastq = Channel.fromPath(params.gex_fastq)
    gex_id = params.gex_id
    cite_fastq = Channel.fromPath(params.cite_fastq)
    cite_id = params.cite_id


    Demultiplex(reference, meta_yaml, gex_fastq, gex_id, cite_fastq, cite_id)
    Demultiplex.out.tar_output.subscribe{it.copyTo(params.demultiplex_output_tar)}


    if(params.tcr_fastq){
        Demultiplex.out.per_sample_data | flatten | BamToFastq

        tcr_fastq = Channel.fromPath(params.tcr_fastq)
        tcr_id = params.tcr_id

        if(params.bcr_fastq){
            bcr_fastq = Channel.fromPath(params.bcr_fastq)
            bcr_id = params.bcr_id
        } else {
            bcr_fastq = Channel.fromPath("NO_FILE")
            bcr_id = "NODATA"
        }

        BamToFastq.out | combine(tcr_fastq) | combine([tcr_id]) |combine(bcr_fastq) | combine([bcr_id])|combine(cite_fastq) | combine([cite_id])| combine(reference) | combine(feature_reference) | combine(vdj_reference) | CellRangerMultiVdj
        CellRangerMultiVdj.out.tar_output.subscribe{it.copyTo(params.vdj_output_dir)}

    }
}
