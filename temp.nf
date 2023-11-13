nextflow.enable.dsl=2
process SWITCH{
    input:
    output:
        stdout emit: mode
    script:
        """
            echo "multiplexed"
        """
}
process INIRUN{
    input:
        val inval
    output:
        stdout
    script:
        """
            echo $inval
        """
}
process DEMULT{
    input:
        val inval
    output:
        stdout
    script:
        """
            echo $inval
        """
}

process BAM2FASTQ{
    input:
        val inval
    output:
        stdout
    script:
        """
            echo $inval
        """
}

process PERSAMPLE{
    input:
        val inval
    output:
        stdout
    script:
        """
            echo $inval
        """
}
workflow {
     SWITCH()
//      SWITCH.out.mode.view()

    SWITCH.out.mode.branch{
        multiplexed: it == 'multiplexed'
        nonmultiplexed: it == 'non-multiplexed'
    }.set{mode}

    mode.multiplexed.view()

    INIRUN(modei)
    INIRUN.out.view()
//     DEMULT(mode.nonmultiplexed)
//     BAM2FASTQ(mode.nonmultiplexed)
//     PERSAMPLE(mode.nonmultiplexed)

}