process CELLRANGER_DEMULTIPLEX {
    time '96h'
    cpus 16
    memory '160 GB'
    label 'process_high'

  input:
    val(mode)
    path(reference)
    path(meta_yaml)
    path(gex_fastq, stageAs: "?/GEX/*")
    val(gex_id)
    path(cite_hto_fastq, stageAs: "?/CITE/*")
    val(cite_hto_id)
    val(sample_id)
  output:
    path("demultiplex_output/outs/per_sample_outs/*"), emit: cellranger_sample_outputs
    path("assignment_confidence_table.csv"), emit: assignment_table
  script:
    def cite_hto_fastq_opt = cite_hto_id != 'NODATA' ? " --cite_hto_fastq ${cite_hto_fastq}" : ''
    def cite_hto_id_opt = cite_hto_id != 'NODATA' ? " --cite_hto_id ${cite_hto_id}" : ''
    """
        cellranger_utils cellranger-demultiplex \
        --reference $reference \
        --meta_yaml $meta_yaml \
        --gex_fastq $gex_fastq \
        --gex_id $gex_id \
        --outdir demultiplex_output \
        --tempdir temp \
        --numcores ${task.cpus} \
        --mempercore 10 \
        --sample_id ${sample_id} \
        $cite_hto_fastq_opt $cite_hto_id_opt

        # Find assignment_confidence_table.csv regardless of output structure
        find demultiplex_output -name "assignment_confidence_table.csv" -exec cp {} assignment_confidence_table.csv \\;

        if [ ! -f assignment_confidence_table.csv ]; then
            echo "ERROR: assignment_confidence_table.csv not found in demultiplex_output" >&2
            echo "Directory contents:" >&2
            find demultiplex_output -type f >&2
            exit 1
        fi
    """
  stub:
    """
    mkdir -p demultiplex_output/outs/per_sample_outs/
    echo "Barcodes,Assignment,Assignment_Probability" > assignment_confidence_table.csv
    """
}
