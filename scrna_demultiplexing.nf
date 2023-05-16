// Declare syntax version
nextflow.enable.dsl=2

process demultiplex {
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
    val(jobmode)
  output:
    path("demultiplex_output/samples/*"), emit: per_sample_data
    path("demultiplex_output/"), emit: demultiplexed_output
  script:
    def cite_fastq_opt = cite_id != 'NODATA' ? " --cite_fastq ${cite_fastq}" : ''
    def cite_id_opt = cite_id != 'NODATA' ? " --cite_id ${cite_id}" : ''
    """
        scrna_demultiplexing_utils cellranger-multi \
        --reference $reference \
        --meta_yaml $meta_yaml \
        --gex_fastq $gex_fastq \
        --gex_id $gex_id \
        --outdir demultiplex_output \
        --tempdir temp \
        --numcores 16 \
        --mempercore 10 \
        --jobmode $jobmode \
        --maxjobs 2000 \
        $cite_fastq_opt $cite_id_opt \

    """
}

process bamtofastq{
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


process per_sample_cell_ranger_multi{
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
            path(meta_yaml),
            path(reference),
            path(vdj_reference),
            val(jobmode)
        )
    output:
        path("${sample_id}"), emit: output
    script:
        def bcr_fastq_opt = bcr_id != 'NODATA' ? " --bcr_fastq ${bcr_fastq}" : ''
        def bcr_id_opt = bcr_id != 'NODATA' ? " --bcr_id ${bcr_id}" : ''
        def tcr_fastq_opt = tcr_id != 'NODATA' ? " --tcr_fastq ${tcr_fastq}" : ''
        def tcr_id_opt = tcr_id != 'NODATA' ? " --tcr_id ${tcr_id}" : ''
        def cite_fastq_opt = cite_id != 'NODATA' ? " --cite_fastq ${cite_fastq}" : ''
        def cite_id_opt = cite_id != 'NODATA' ? " --cite_id ${cite_id}" : ''
        """
            scrna_demultiplexing_utils  cellranger-multi-vdj \
            --reference $reference \
            --vdj_reference $vdj_reference \
            --gex_fastq $gex_fastq \
            --gex_id bamtofastq \
            --gex_metrics $gex_metrics \
            --output ${sample_id} \
            --meta_yaml $meta_yaml \
            --tempdir temp \
            --sample_id $sample_id \
            --numcores 16 \
            --mempercore 10 \
            --jobmode $jobmode \
            --maxjobs 2000 \
            $bcr_fastq_opt $bcr_id_opt \
            $tcr_fastq_opt $tcr_id_opt \
            $cite_fastq_opt $cite_id_opt \
        """
}



process DemultiplexOutput {
    publishDir "${params.output_dir}/demultiplexing/", mode: 'copy', pattern: "*"
    input:
        path demultiplex_tar
    output:
        path demultiplex_tar
    """
    echo "Writing output files"
    """
}

process VdjOutput {
    publishDir "${params.output_dir}/per_sample_outs/", mode: 'copy', pattern: "*"
    input:
        path demultiplex_tar
    output:
        path demultiplex_tar
    """
    echo "Writing output files"
    """
}



workflow{
    reference = Channel.fromPath(params.reference)
    vdj_reference = Channel.fromPath(params.vdj_reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)
    jobmode = params.jobmode

    gex_fastq = Channel.fromPath(params.gex_fastq)
    gex_id = params.gex_id

    if(params.cite_fastq){
        cite_fastq = params.cite_fastq
        cite_id = params.cite_id
    } else {
        cite_fastq = "/path/NO_FILE"
        cite_id = "NODATA"
    }

    Demultiplex(reference, meta_yaml, gex_fastq, gex_id, cite_fastq, cite_id, jobmode)
    DemultiplexOutput(Demultiplex.out.demultiplexed_output)


    demux_channel = Demultiplex.out.per_sample_data.flatten()
    BamToFastq(demux_channel)

    if(params.tcr_fastq){
        tcr_fastq = params.tcr_fastq
        tcr_id = params.tcr_id
    } else {
        tcr_fastq = "/path/NO_FILE"
        tcr_id = "NODATA"
    }


    if(params.bcr_fastq){
        bcr_fastq = params.bcr_fastq
        bcr_id = params.bcr_id
    } else {
        bcr_fastq = "/path/NO_FILE"
        bcr_id = "NODATA"
    }

    new_channel = BamToFastq.out.map{
        it -> [
            it[0], it[1], it[2], tcr_fastq, tcr_id,
            bcr_fastq, bcr_id, params.cite_fastq, params.cite_id,
            params.meta_yaml, params.reference,
            params.vdj_reference, params.jobmode
        ]
    }

    CellRangerMultiVdj(new_channel)
    VdjOutput(CellRangerMultiVdj.out.output)
}
