// Declare syntax version
nextflow.enable.dsl=2



process Demultiplex {
    time '96h'
    cpus 16
    memory '10 GB'

  input:
    path(reference)
    path(cmo_tsv)
    path(gex_fastq)
    path(multiplex_capture_fastq)
  output:
    path("outdir/*bam"), emit: bam_files
    path("outdir/metrics.csv"), emit: metrics_csv
 script:
    """
        scrna_multiplex_utils cellranger_multi --memory 10 --cores 16 \
        --reference $reference \
        --meta_yaml meta_yaml \
        --gex_fastq $gex_fastq \
        --cite_fastq $cite_fastq \
        --tempdir tempdir
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

    Demultiplex(reference, meta_yaml, gex_fastq, cite_fastq)

}

