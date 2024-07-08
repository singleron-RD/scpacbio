process PBMM2 {
    tag "$meta.id"
    label 'process_high'

    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbmm2:1.14.99--h9ee0642_0 ' :
        'biocontainers/pbmm2:1.14.99--h9ee0642_0 ' }"
    

    input:
    tuple val(meta), path(bam)
    path reference

    output:
    tuple val(meta), path('*.mapped.bam'),    emit:map_bam

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pbmm2 align \\
    -j $task.cpus \\
    $args \\
    ${reference} \\
    ${bam} \\
    ${prefix}.mapped.bam
    """
}