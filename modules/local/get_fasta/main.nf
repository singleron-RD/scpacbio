process GET_FASTA {
    tag "$meta.id"
    label 'custome'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_0 ' :
        'biocontainers/samtools:1.20--h50ea8bc_0 ' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path('*.dedup.fasta'), emit: dedup_fasta

    script:
    def prefix   = task.ext.prefix ?: "${meta.id}"

    """
    get_fasta.sh ${bam} ${prefix}.dedup.fasta
    """
}
