nextflow.enable.dsl=2

include { CELLRANGER_IS_MULTIPLEXED         } from '../../modules/local/cellranger_is_multiplexed'
include { CELLRANGER_NON_MULTIPLEXED         } from '../../modules/local/cellranger_non_multiplexed'
include { CELLRANGER_DEMULTIPLEX         } from '../../modules/local/cellranger_demultiplex'
include { CELLRANGER_BAMTOFASTQ         } from '../../modules/local/cellranger_bamtofastq'
include { CELLRANGER_PER_SAMPLE         } from '../../modules/local/cellranger_per_sample'
include { SPLIT_FASTQS_BY_BARCODE as SPLIT_GEX   } from '../../modules/local/split_fastqs_by_barcode'
include { SPLIT_FASTQS_BY_BARCODE as SPLIT_CITE  } from '../../modules/local/split_fastqs_by_barcode'
include { SPLIT_FASTQS_BY_BARCODE as SPLIT_TCR   } from '../../modules/local/split_fastqs_by_barcode'
include { SPLIT_FASTQS_BY_BARCODE as SPLIT_BCR   } from '../../modules/local/split_fastqs_by_barcode'


workflow CELLRANGER_WF{

    take:
        reference
        vdj_reference
        meta_yaml
        gex_fastq
        gex_id
        cite_fastq
        cite_id
        tcr_fastq
        tcr_id
        bcr_fastq
        bcr_id
        sample_id

    main:


    CELLRANGER_IS_MULTIPLEXED(meta_yaml, cite_id, tcr_id, bcr_id)

    mode = CELLRANGER_IS_MULTIPLEXED.out.mode.branch{
        multiplexed: it.toInteger() == 1
        nonmultiplexed: it.toInteger() == 0
    }

    CELLRANGER_NON_MULTIPLEXED(
            mode.nonmultiplexed,
            reference,
            vdj_reference,
            gex_fastq,
            gex_id,
            meta_yaml,
            sample_id,
            cite_fastq,
            cite_id,
            bcr_fastq,
            bcr_id,
            tcr_fastq,
            tcr_id
    )


    CELLRANGER_DEMULTIPLEX(
            mode.multiplexed,
            reference,
            meta_yaml,
            gex_fastq,
            gex_id,
            cite_fastq,
            cite_id,
            sample_id,
    )


    demux_channel = CELLRANGER_DEMULTIPLEX.out.cellranger_sample_outputs.flatten()
    CELLRANGER_BAMTOFASTQ(demux_channel)

    // Split multiplexed FASTQs into per-sample FASTQs by barcode assignment
    assignment_table = CELLRANGER_DEMULTIPLEX.out.assignment_table

    // Always split GEX
    SPLIT_GEX(assignment_table, gex_fastq, 'GEX')

    // Conditionally split other modalities if they were provided
    if (params.cite_id) {
        SPLIT_CITE(assignment_table, cite_fastq, 'CITE')
    }
    if (params.tcr_id) {
        SPLIT_TCR(assignment_table, tcr_fastq, 'TCR')
    }
    if (params.bcr_id) {
        SPLIT_BCR(assignment_table, bcr_fastq, 'BCR')
    }

    if (!params.demux_only) {
        new_channel = CELLRANGER_BAMTOFASTQ.out.map{
            it -> [
                it[0], it[1], it[2], tcr_fastq, tcr_id,
                bcr_fastq, bcr_id, params.cite_fastq, params.cite_id,
                params.meta_yaml, params.reference,
                params.vdj_reference
            ]
        }

        CELLRANGER_PER_SAMPLE(new_channel)
    }

}
