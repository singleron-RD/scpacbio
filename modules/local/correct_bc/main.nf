process CORRECT_BC {
    tag "$meta.id"
    label 'custome'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.1--py39hcada746_0' :
        'biocontainers/pysam:0.22.1--py39hcada746_0' }"

    input:
    tuple val(meta),path(correct_bc)
    tuple val(meta),path(bam)

    output:
    tuple val(meta),path('*.sgr.bam'), emit: correct_bam

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    correct_bc.py ${correct_bc} ${bam} ${prefix}.sgr.bam
    """
}
