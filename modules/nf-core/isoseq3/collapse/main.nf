process ISOSEQ3_COLLAPSE {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/isoseq3:3.8.2--h9ee0642_0' :
        'biocontainers/isoseq3:3.8.2--h9ee0642_0' }"


    input:
    tuple val(meta), path(bam_map)

    output:
    tuple val(meta), path("*.gff"), emit: gff     // _rmdup is hardcoded output from dedup
    tuple val(meta), path("*.abundance.txt"), emit: abundance
    tuple val(meta), path("*.fasta"),       emit: fasta
    tuple val(meta), path("*.group.txt"),   emit: group
    tuple val(meta), path("*.fastq"),       emit: fastq
    tuple val(meta), path("*.report.json"), emit: json
    tuple val(meta), path("*.read_stat.txt"), emit: read_stat
    

    //tuple val(meta), path("*.dedup.fasta"), emit: dedup_fasta
    //tuple val(meta), path("*.hist")     , emit: hist
    //tuple val(meta), path("*log")       , emit: log
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"

    """
    isoseq3 \\
        collapse \\
        -j $task.cpus \\
        ${bam_map} \\
        collapse.gff 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        isoseq3: \$( echo \$(isoseq3 --version 2>&1) | tail -n 1 | sed 's/.* v//')

    END_VERSIONS
    """
}