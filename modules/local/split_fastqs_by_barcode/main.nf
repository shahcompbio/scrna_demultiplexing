process SPLIT_FASTQS_BY_BARCODE {
    publishDir "${params.output_dir}/demux_fastqs",
        mode: 'copy',
        enabled: params.save_demux_fastqs ?: false
    time '24h'
    cpus 1
    memory '16 GB'
    label 'process_medium'

    input:
        path(assignment_table)
        path(fastq_dir)
        val(modality)

    output:
        path("output/*"), emit: per_sample_fastqs
        path("output/${modality}_split_summary.csv"), emit: split_summary

    script:
        """
        split_fastqs_by_barcode.py \
            --assignment_table ${assignment_table} \
            --fastq_dir ${fastq_dir} \
            --outdir output \
            --modality ${modality} \
            --min_assignment_confidence ${params.min_assignment_confidence ?: 0.9}
        """

    stub:
        """
        mkdir -p output/SampleA/${modality}
        mkdir -p output/SampleB/${modality}
        touch output/${modality}_split_summary.csv
        """
}
