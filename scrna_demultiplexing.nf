// Declare syntax version
nextflow.enable.dsl=2



process Demultiplex {
    time '96h'
    cpus 16
    memory '10 GB'

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
    path("output/outs/per_sample_outs/*/metrics_summary.csv"), emit: metrics_csv
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
        --tempdir temp
    """
}



workflow{

    reference = Channel.fromPath(params.reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)
    gex_fastq = Channel.fromPath(params.gex_fastq)
    cite_fastq = Channel.fromPath(params.cite_fastq)


    Demultiplex(reference, meta_yaml, gex_fastq, params.gex_id, cite_fastq, params.cite_id)

}

