process CELLRANGER_BAMTOFASTQ{
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
            demultiplexing_utils.py bam-to-fastq \
              --bam_file $per_sample_data/*bam \
              --metrics $per_sample_data/*metrics_summary.csv \
              --outdir output \
              --tempdir temp
        """
    stub:
        sample_id = "${per_sample_data.baseName}"
        """
        mkdir output
        """
}
