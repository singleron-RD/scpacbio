process LIMA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lima:2.9.0--h9ee0642_1' :
        'biocontainers/lima:2.9.0--h9ee0642_1' }"

    input:
    tuple val(meta), path(reads)
    path primers

    output:
    tuple val(meta), path("*.counts") , emit: counts
    tuple val(meta), path("*.report") , emit: report
    tuple val(meta), path("*.summary"), emit: summary
    tuple val(meta), path("*.5p--3p.bam"), emit: p53_bam
    path "versions.yml"               , emit: versions

    tuple val(meta), path("*.bam")              , optional: true, emit: bam
    tuple val(meta), path("*.bam.pbi")          , optional: true, emit: pbi
    tuple val(meta), path("*.{fa, fasta}")      , optional: true, emit: fasta
    tuple val(meta), path("*.{fa.gz, fasta.gz}"), optional: true, emit: fastagz
    tuple val(meta), path("*.fastq")            , optional: true, emit: fastq
    tuple val(meta), path("*.fastq.gz")         , optional: true, emit: fastqgz
    tuple val(meta), path("*.xml")              , optional: true, emit: xml
    tuple val(meta), path("*.json")             , optional: true, emit: json
    tuple val(meta), path("*.clips")            , optional: true, emit: clips
    tuple val(meta), path("*.guess")            , optional: true, emit: guess

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if( "$reads" == "${prefix}.bam" )      error "Input and output names are the same, set prefix in module configuration"
    if( "$reads" == "${prefix}.fasta" )    error "Input and output names are the same, set prefix in module configuration"
    if( "$reads" == "${prefix}.fasta.gz" ) error "Input and output names are the same, set prefix in module configuration"
    if( "$reads" == "${prefix}.fastq" )    error "Input and output names are the same, set prefix in module configuration"
    if( "$reads" == "${prefix}.fastq.gz" ) error "Input and output names are the same, set prefix in module configuration"

    """
    OUT_EXT=""

    if [[ $reads =~ bam\$ ]]; then
        OUT_EXT="bam"
    elif [[ $reads =~ fasta\$ ]]; then
        OUT_EXT="fasta"
    elif [[ $reads =~ fasta.gz\$ ]]; then
        OUT_EXT="fasta.gz"
    elif [[ $reads =~ fastq\$ ]]; then
        OUT_EXT="fastq"
    elif [[ $reads =~ fastq.gz\$ ]]; then
        OUT_EXT="fastq.gz"
    fi

    lima \\
        $reads \\
        $primers \\
        $prefix.\$OUT_EXT \\
        -j $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lima: \$( lima --version | head -n1 | sed 's/lima //g' | sed 's/ (.\\+//g' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch dummy.counts
    touch dummy.report
    touch dummy.summary

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lima: \$( lima --version | head -n1 | sed 's/lima //g' | sed 's/ (.\\+//g' )
    END_VERSIONS
    """
}