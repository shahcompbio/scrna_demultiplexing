nextflow.enable.dsl=2



process DEMULTIPLEXOUTPUT {
    publishDir "${params.output_dir}/demultiplexing/", mode: 'copy', pattern: "*"
    input:
        path demultiplex_tar
    output:
        path demultiplex_tar
    """
    echo "Writing output files"
    """
}

process PERSAMPLEOUTPUT {
    publishDir "${params.output_dir}/per_sample_outs/", mode: 'copy', pattern: "*"
    input:
        path demultiplex_tar
    output:
        path demultiplex_tar
    """
    echo "Writing output files"
    """
}



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
    cite_fastq = "/path/NO_FILE"
    cite_id = "NODATA"
}

if(params.tcr_fastq){
    tcr_fastq = params.tcr_fastq
    tcr_id = params.tcr_id
} else {
    tcr_fastq = "/path/NO_FILE"
    tcr_id = "NODATA"
}


if(params.bcr_fastq){
    bcr_fastq = params.bcr_fastq
    bcr_id = params.bcr_id
} else {
    bcr_fastq = "/path/NO_FILE"
    bcr_id = "NODATA"
}





////////////////////////////////////////////////////
/* --    IMPORT LOCAL MODULES/SUBWORKFLOWS     -- */
////////////////////////////////////////////////////

include { CELLRANGER_BAMTOFASTQ         } from '../modules/local/cellranger_bamtofastq'
include { CELLRANGER_DEMULTIPLEX         } from '../modules/local/cellranger_demultiplex'
include { CELLRANGER_PERSAMPLE         } from '../modules/local/cellranger_persample'


workflow DEMULTIPLEX{
    reference = Channel.fromPath(params.reference)
    vdj_reference = Channel.fromPath(params.vdj_reference)
    meta_yaml = Channel.fromPath(params.meta_yaml)
    jobmode = params.jobmode

    gex_fastq = Channel.fromPath(params.gex_fastq)
    gex_id = params.gex_id


    CELLRANGER_DEMULTIPLEX(reference, meta_yaml, gex_fastq, gex_id, cite_fastq, cite_id, jobmode)
    // DEMULTIPLEXOUTPUT(CELLRANGER_DEMULTIPLEX.out.demultiplexed_output)


    demux_channel = CELLRANGER_DEMULTIPLEX.out.per_sample_data.flatten()
    CELLRANGER_BAMTOFASTQ(demux_channel)


    new_channel = CELLRANGER_BAMTOFASTQ.out.map{
        it -> [
            it[0], it[1], it[2], tcr_fastq, tcr_id,
            bcr_fastq, bcr_id, params.cite_fastq, params.cite_id,
            params.meta_yaml, params.reference,
            params.vdj_reference, params.jobmode
        ]
    }

    CELLRANGER_PERSAMPLE(new_channel)
    // PERSAMPLEOUTPUT(CELLRANGER_PERSAMPLE.out.output)
}
