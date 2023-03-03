// Declare syntax version
nextflow.enable.dsl=2



process Demultiplex {
    time '96h'
    cpus 8
    memory '10 GB'

  input:
    path(reference)
    path(cmo_tsv)
    path(gex_fastq)
    path(multiplex_capture_fastq)
  output:
    path("outdir/*")
 script:
    """
        vdj_utils cellranger_multi --memory 10 --cores 8 \
        --reference $reference \
        --cmo_tsv $cmo_tsv \
        --gex_fastq $gex_fastq \
        --multiplex_capture_fastq $multiplex_capture_fastq
    """
}


workflow{

    reference = Channel.fromPath(params.reference)
    cmo_tsv = Channel.fromPath(params.cmo_tsv)
    gex_fastq = Channel.fromPath(params.gex_fastq)
    multiplex_capture_fastq = Channel.fromPath(params.multiplex_capture_fastq)

    Demultiplex(reference, cmo_tsv_ch, gex_fastq_ch, multiplex_capture_fastq)

}

