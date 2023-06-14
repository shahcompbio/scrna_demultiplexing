process CELLRANGER_BAMTOFASTQ{
    time '96h'
    cpus 1
    memory '10 GB'

    input:
        path(per_sample_data)
    output:
        tuple(val("${per_sample_data.baseName}"), path("output"), path("${per_sample_data}/*metrics_summary.csv"))
    script:
        """
            demultiplexing_utils.py bam-to-fastq \
              --bam_file $per_sample_data/*bam \
              --metrics $per_sample_data/*metrics_summary.csv \
              --outdir output \
              --tempdir temp
        """
    stub:
        """
        mkdir output
        mkdir -p "${per_sample_data.baseName}"
        touch "${per_sample_data.baseName}/metrics_summary.csv"
        """
}
