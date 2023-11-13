nextflow.enable.dsl=2

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////
if (params.reference) {reference = file(params.reference)} else { exit 1, 'reference dir not specified. Please, provide --reference_dir <PATH/TO/reference> !' }

if (params.vdj_reference) {vdj_reference = file(params.vdj_reference)} else { exit 1, 'vdj reference dir not specified. Please, provide --vdj_reference_dir <PATH/TO/vdj_reference> !' }

if (params.meta_yaml) {meta_yaml = file(params.meta_yaml)} else { exit 1, 'meta yaml not specified. Please, provide --meta_yaml <PATH/TO/meta_yaml> !' }

if (params.sample_id) {sample_id = params.sample_id} else { exit 1, 'sample_id not specified. Please, provide --sample_id <id> !' }

if (params.gex_fastq) {
    gex_fastq = file(params.gex_fastq)
    gex_id = params.gex_id
} else {
    exit 1, 'gex_fastq not specified!'
}

if(params.cite_fastq){
    cite_fastq = file(params.cite_fastq)
    cite_id = params.cite_id
} else {
    cite_fastq = file("$baseDir/assets/dummy_file.txt")
    cite_id = "NODATA"
}

if(params.tcr_fastq){
    tcr_fastq = file(params.tcr_fastq)
    tcr_id = params.tcr_id
} else {
    tcr_fastq = file("$baseDir/assets/dummy_file.txt")
    tcr_id = "NODATA"
}

if(params.bcr_fastq){
    bcr_fastq = file(params.bcr_fastq)
    bcr_id = params.bcr_id
} else {
    bcr_fastq = file("$baseDir/assets/dummy_file.txt")
    bcr_id = "NODATA"
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CELLRANGER_WF         } from '../subworkflows/local/cellranger'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SCRNA_CELLRANGER_PIPELINE{

    CELLRANGER_WF(
        reference,
        vdj_reference,
        meta_yaml,
        gex_fastq,
        gex_id,
        cite_fastq,
        cite_id,
        tcr_fastq,
        tcr_id,
        bcr_fastq,
        bcr_id,
        sample_id
    )

}
