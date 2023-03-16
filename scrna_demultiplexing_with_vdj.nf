// Declare syntax version
nextflow.enable.dsl=2



process Demultiplex {
    time '6h'
    cpus 1
    memory '5 GB'

  input:
    path(reference)
    path(meta_yaml)
    path(gex_fastq, stageAs: "?/1/*")
    val(gex_id)
    path(cite_fastq, stageAs: "?/2/*")
    val(cite_id)
  output:
    path("output/outs/per_sample_outs/*/count/sample_alignments.bam"), emit: bam_files
    path("output/outs/per_sample_outs/*/count/sample_alignments.bam.bai"), emit: bai_files
    path("output/outs/per_sample_outs/*/metrics_summary.csv"), emit: metrics
 script:
    """
        scrna_demultiplexing_utils cellranger-multi \
        --reference $reference \
        --meta_yaml $meta_yaml \
        --gex_fastq $gex_fastq \
        --gex_id $gex_id \
        --cite_fastq $cite_fastq \
        --cite_id $cite_id \
        --outdir output \
        --tempdir temp \
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
        tuple(path(bam_file), path(bai_file), path(metrics))
    output:
        path("output")
    script:
    """
        scrna_demultiplexing_utils bam-to-fastq \
          --bam_file $bam_file \
          --metrics $metrics \
          --outdir output \
          --tempdir temp
    """

}


process CellRangerMultiVdj{
    time '96h'
    cpus 1
    memory '10 GB'

    input:
        tuple(path(gex_fastq), path(gex_metrics), path(tcr_fastq), val(tcr_id), path(reference), path(feature_reference), path(vdj_reference))
    output:
        path("*")
    script:
    """
        which cellranger

        scrna_demultiplexing_utils  cellranger-multi-vdj \
        --reference $reference \
        --feature_reference $feature_reference \
        --vdj_reference $vdj_reference \
        --gex_fastq $gex_fastq \
        --gex_id bamtofastq \
        --gex_metrics $gex_metrics \
        --tcr_fastq $tcr_fastq \
        --tcr_id $tcr_id \
        --outdir cellranger_output \
        --tempdir temp \
        --numcores 16 \
        --mempercore 10 \
        --jobmode lsf \
        --maxjobs 2000
    """
}

//process: run cell ranger vdj with gex+tcr



workflow{

    reference = Channel.fromPath(params.reference)
    feature_reference = Channel.fromPath(params.feature_reference)
    vdj_reference = Channel.fromPath(params.vdj_reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)
    gex_fastq = Channel.fromPath(params.gex_fastq)
    gex_id = params.gex_id
    cite_fastq = Channel.fromPath(params.cite_fastq)
    cite_id = params.cite_id
    tcr_fastq = Channel.fromPath(params.tcr_fastq)
    tcr_id = params.tcr_id

    Demultiplex(reference, meta_yaml, gex_fastq, gex_id, cite_fastq, cite_id) | set{sample_outs}

    sample_outs.bam_files | flatten | set{bams}
    sample_outs.bai_files | flatten | set{bais}
    sample_outs.metrics | flatten | set{metrics}

    bams | merge(bais)| merge(metrics) | BamToFastq | set{gex_fastqs}

    gex_fastqs | flatten | merge(metrics) | combine(tcr_fastq) | combine([tcr_id])| combine(reference) | combine(feature_reference) | combine(vdj_reference) | CellRangerMultiVdj

}

