// Declare syntax version
nextflow.enable.dsl=2



process Demultiplex {
    time '96h'
    cpus 8
    memory '10 GB'

  input:
    path(demux_csv_file)
    val(memory)
    val(cores)
  output:
    path("outdir/*")
 script:
    """
        vdj_utils cellranger_multi --csv $demux_csv_file --memory 10 --cores 8
    """
}


workflow{

    chromosomes_ch = Channel.from(params.chromosomes)
    vcf = Channel.fromPath(params.vcf)
    vcf_idx = Channel.fromPath(params.vcf_idx)
    reference_haplotyping_tar = Channel.fromPath(params.ref_tar)


    chromosomes_ch | flatten | combine(vcf)|combine(vcf_idx) | BcftoolsConvert | combine(reference_haplotyping_tar) | ShapeIt4

    CsverveConcat(ShapeIt4.out.haps_csv.collect(), ShapeIt4.out.haps_csv_yaml.collect())

    CsverveConcat.out.csv_file.subscribe { it.copyTo(params.out_csv) }
    CsverveConcat.out.csv_file.subscribe { it.copyTo(params.out_csv_yaml) }
}

