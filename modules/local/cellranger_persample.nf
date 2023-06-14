process CELLRANGER_PERSAMPLE{
    time '96h'
    cpus 16
    memory '12 GB'
    label 'cellranger'


    input:
        tuple(
            val(sample_id),
            path(gex_fastq, stageAs: "?/GEX/*"),
            path(gex_metrics),
            path(tcr_fastq, stageAs: "?/TCR/*"),
            val(tcr_id),
            path(bcr_fastq, stageAs: "?/BCR/*"),
            val(bcr_id),
            path(cite_fastq, stageAs: "?/CITE/*"),
            val(cite_id),
            path(meta_yaml),
            path(reference),
            path(vdj_reference),
            val(jobmode),
            val(numcores)
        )
    output:
        path("${sample_id}"), emit: output
    script:
        def bcr_fastq_opt = bcr_id != 'NODATA' ? " --bcr_fastq ${bcr_fastq}" : ''
        def bcr_id_opt = bcr_id != 'NODATA' ? " --bcr_id ${bcr_id}" : ''
        def tcr_fastq_opt = tcr_id != 'NODATA' ? " --tcr_fastq ${tcr_fastq}" : ''
        def tcr_id_opt = tcr_id != 'NODATA' ? " --tcr_id ${tcr_id}" : ''
        def cite_fastq_opt = cite_id != 'NODATA' ? " --cite_fastq ${cite_fastq}" : ''
        def cite_id_opt = cite_id != 'NODATA' ? " --cite_id ${cite_id}" : ''
        """
            demultiplexing_utils.py  cellranger-multi-vdj \
            --reference $reference \
            --vdj_reference $vdj_reference \
            --gex_fastq $gex_fastq \
            --gex_id bamtofastq \
            --gex_metrics $gex_metrics \
            --output ${sample_id} \
            --meta_yaml $meta_yaml \
            --tempdir temp \
            --sample_id $sample_id \
            --numcores $numcores \
            --mempercore 10 \
            --jobmode $jobmode \
            --maxjobs 2000 \
            $bcr_fastq_opt $bcr_id_opt \
            $tcr_fastq_opt $tcr_id_opt \
            $cite_fastq_opt $cite_id_opt \
        """
    stub:
        """
            mkdir $sample_id
        """
}