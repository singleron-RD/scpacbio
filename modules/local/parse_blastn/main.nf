process PARSE_BLASTN {
    tag "$meta.id"
    label 'custome'

    input:
    tuple val(meta),path(white_list)
    path bclist

    output:
    tuple val(meta),path('*.bc_correct.txt'), emit: txt

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    parse_blastn.py ${bclist} ${white_list} ${prefix}.bc_correct.txt
    """
}
