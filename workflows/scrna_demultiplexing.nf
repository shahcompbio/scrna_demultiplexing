nextflow.enable.dsl=2



////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////


if (!params.reference) {
    exit 1, 'reference dir not specified!'
}

if (!params.vdj_reference) {
    exit 1, 'vdj reference dir not specified!'
}

if (!params.meta_yaml) {
    exit 1, 'meta_yaml not specified!'
}

if (params.gex_fastq) {
    gex_input = Channel.fromPath(params.gex_fastq)
    gex_id = params.gex_id
} else {
    exit 1, 'gex_fastq not specified!'
}


if(params.cite_fastq){
    cite_fastq = params.cite_fastq
    cite_id = params.cite_id
} else {
    cite_fastq = file("$baseDir/assets/dummy_file.txt")
    cite_id = "NODATA"
}

if(params.tcr_fastq){
    tcr_fastq = params.tcr_fastq
    tcr_id = params.tcr_id
} else {
    tcr_fastq = file("$baseDir/assets/dummy_file.txt")
    tcr_id = "NODATA"
}


if(params.bcr_fastq){
    bcr_fastq = params.bcr_fastq
    bcr_id = params.bcr_id
} else {
    bcr_fastq = file("$baseDir/assets/dummy_file.txt")
    bcr_id = "NODATA"
}





////////////////////////////////////////////////////
/* --    IMPORT LOCAL MODULES/SUBWORKFLOWS     -- */
////////////////////////////////////////////////////

include { CELLRANGER_BAMTOFASTQ         } from '../modules/local/cellranger_bamtofastq'
include { CELLRANGER_DEMULTIPLEX         } from '../modules/local/cellranger_demultiplex'
include { CELLRANGER_PERSAMPLE         } from '../modules/local/cellranger_persample'
include { CELLRANGER_CHECK_HTO         } from '../modules/local/cellranger_check_hto'
include { CELLRANGER_NONMULTIPLEXED         } from '../modules/local/cellranger_non_multiplexed'


workflow DEMULTIPLEX{
    reference = Channel.fromPath(params.reference)
    vdj_reference = Channel.fromPath(params.vdj_reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)

    gex_fastq = Channel.fromPath(params.gex_fastq)
    gex_id = params.gex_id

    sample_id = params.sample_id

    CELLRANGER_CHECK_HTO(meta_yaml, cite_id, tcr_id, bcr_id)

    if (CELLRANGER_CHECK_HTO.out == "non-multiplexed"){
        CELLRANGER_NONMULTIPLEXED(
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
    }
    else{
        CELLRANGER_CHECK_HTO.out.view()
        exit 1, 'other!'
    }


//     CELLRANGER_DEMULTIPLEX(reference, meta_yaml, gex_fastq, gex_id, cite_fastq, cite_id)
//
//
//     demux_channel = CELLRANGER_DEMULTIPLEX.out.per_sample_data.flatten()
//     CELLRANGER_BAMTOFASTQ(demux_channel)
//
//     new_channel = CELLRANGER_BAMTOFASTQ.out.map{
//         it -> [
//             it[0], it[1], it[2], tcr_fastq, tcr_id,
//             bcr_fastq, bcr_id, params.cite_fastq, params.cite_id,
//             params.meta_yaml, params.reference,
//             params.vdj_reference
//         ]
//     }
//
//     CELLRANGER_PERSAMPLE(new_channel)
}
