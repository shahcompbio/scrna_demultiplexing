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
        --tempdir temp
    """
}

process BamToFastq{
    input:
        tuple(path(bam_file), path(bai_file), path(metrics))
    output:
        path("output/*")
    script:
    """
        scrna_demultiplexing_utils bam-to-fastq \
          --bam_file $bam_file \
          --metrics $metrics \
          --outdir output \
          --tempdir temp
    """

}




// on each bam from demultiplex
//process: bamtofastq{}
// also needs to look at the input bam file to detect the gex and cite fastqs
// depends on CO in header

//process: run cell ranger vdj with gex+tcr



workflow{

    reference = Channel.fromPath(params.reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)
    gex_fastq = Channel.fromPath(params.gex_fastq)
    cite_fastq = Channel.fromPath(params.cite_fastq)

    Demultiplex(reference, meta_yaml, gex_fastq, params.gex_id, cite_fastq, params.cite_id) | set{sample_outs}

    sample_outs.bam_files | flatten | set{bams}
    sample_outs.bai_files | flatten | set{bais}
    sample_outs.metrics | flatten | set{metrics}


    bams | merge(bais)| merge(metrics) | BamToFastq


}

