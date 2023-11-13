#!/usr/bin/env nextflow

import groovy.json.JsonBuilder
// Declare syntax version
nextflow.enable.dsl=2




//WorkflowMain.initialise(workflow, params, log)



include { SCRNA_CELLRANGER_PIPELINE } from './workflows/scrna_cellranger'

//
// WORKFLOW: Run main demultiplex analysis pipeline
//
workflow SCRNA_CELLRANGER {
    SCRNA_CELLRANGER_PIPELINE ()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
//
workflow {
    SCRNA_CELLRANGER ()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
