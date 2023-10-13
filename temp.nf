nextflow.enable.dsl=2
process SWITCH{
    input:
        val input
    output:
        stdout
    script:
        """
            echo "multiplexed"
        """
}

workflow {
    SWITCH(params.input)
    SWITCH.out.view()
//     if (SWITCH.out == 'multiplexed'){
//         exit 1, 'multiplexed'
//     }
//     else{
//         exit 1, 'other!'
//     }
}