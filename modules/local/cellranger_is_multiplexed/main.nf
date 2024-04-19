process CELLRANGER_IS_MULTIPLEXED{
    time '96h'
    cpus 1
    memory '10 GB'
    label 'process_low'

    input:
        path(meta_yaml)
        val(cite_hto_id)
        val(tcr_id)
        val(bcr_id)
    output:
        stdout emit:mode
    script:
        def bcr_id_opt = bcr_id != 'NODATA' ? " --bcr_id ${bcr_id}" : ''
        def tcr_id_opt = tcr_id != 'NODATA' ? " --tcr_id ${tcr_id}" : ''
        def cite_hto_id_opt = cite_hto_id != 'NODATA' ? " --cite_hto_id ${cite_hto_id}" : ''

        """
            cat ${meta_yaml}
            echo ${bcr_id_opt}
            mode=`cellranger_utils check-multiplex-status --meta_yaml ${meta_yaml} $bcr_id_opt $tcr_id_opt $cite_hto_id_opt`
            echo ${mode}
            if [ "\${mode}" = "multiplexed" ]; then
                echo "1"
            else
                echo "0"
            fi
        """
    stub:
        """
        echo "1"
        """
}
