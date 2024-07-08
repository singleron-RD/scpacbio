process PIGEON_SORT {
    tag "$meta.id"
    label 'process_high'

    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbpigeon:1.2.0--h4ac6f70_0 ' :
        'biocontainers/pbpigeon:1.2.0--h4ac6f70_0 ' }"
    

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path('*.sorted.gff'),    emit:sort_gff

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pigeon sort \\
    ${gff} \\
    -o ${prefix}.collapse.sorted.gff
    """
}