process CELLRANGER_BAMTOFASTQ{
    time '96h'
    cpus 1
    memory '10 GB'
    label 'process_medium'

    input:
        path(cellranger_dir)
    output:
        tuple(val("${cellranger_dir.baseName}"), path("output"), path("output/metrics.csv"))
    script:
        """
            cellranger_utils bam-to-fastq \
              --cellranger_demultiplex_dir ${cellranger_dir} \
              --outdir output \
              --tempdir temp
        """
    stub:
        """
        mkdir output
        mkdir -p "${cellranger_dir.baseName}"
        touch "output/metrics_summary.csv"
        """
}
