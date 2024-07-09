process EXTRACT_BC {
    tag "$meta.id"
    label 'custome'

    //conda 'conda-forge::python==3.12'
    //container "biocontainers/python:3.12"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.1--py39hcada746_0' :
        'biocontainers/pysam:0.22.1--py39hcada746_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path('align_bc_8.fa'), emit: bc8_fa

    script:
    """
    extract_bc.py ${bam} 'align_bc_8.fa'
    """
}
