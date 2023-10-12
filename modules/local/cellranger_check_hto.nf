process CELLRANGER_CHECK_HTO{
    time '96h'
    cpus 1
    memory '10 GB'

    input:
        path(meta_yaml)
        val(cite_hto_id)
        val(tcr_id)
        val(bcr_id)
    output:
        stdout
    script:
        def bcr_id_opt = bcr_id != 'NODATA' ? " --bcr_id ${bcr_id}" : ''
        def tcr_id_opt = tcr_id != 'NODATA' ? " --tcr_id ${tcr_id}" : ''
        def cite_hto_id_opt = cite_hto_id != 'NODATA' ? " --cite_hto_id ${cite_hto_id}" : ''

        """
            cellranger_utils check_multiplex_status \
              --meta_yaml ${meta_yaml} \
              $bcr_id_opt $tcr_id_opt $cite_hto_id_opt
        """
    stub:
        """
        echo "multiplexed"
        """
}
