/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_scpacbio_pipeline'

//include { REMOVE_PRIMER          } from '../modules/nf-core/remove_primer/main'
include { LIMA                     } from '../modules/nf-core/lima/main'
include { ISOSEQ3_TAG              } from '../modules/nf-core/isoseq3/tag/main'
include { ISOSEQ3_REFINE           } from '../modules/nf-core/isoseq3/refine/main'
include { EXTRACT_BC               } from '../modules/local/extract_bc/main'
include { BLAST_BLASTN             } from '../modules/nf-core/blastn/main'
include { PARSE_BLASTN             } from '../modules/local/parse_blastn/main'
include { CORRECT_BC               } from '../modules/local/correct_bc/main'
include { SAMTOOLS_BC              } from '../modules/nf-core/isoseq3/dedup/main'
include { ISOSEQ3_DEDUP            } from '../modules/nf-core/isoseq3/dedup/main'
include { PBMM2                    } from '../modules/nf-core/pbmm2/main'
//include { GET_FASTA                } from '../modules/local/get_fasta/main'
//include { MINIMAP2_ALIGN           } from '../modules/nf-core/minimap2/main'
include { ISOSEQ3_COLLAPSE         } from '../modules/nf-core/isoseq3/collapse/main'
include { PIGEON_SORT              } from '../modules/nf-core/pigeon/main'
//include { PBINDEX                  } from '../modules/nf-core/pbindex/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SCPACBIO {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    //
    // MODULE: REMOVE_PRIMER
    //
    //REMOVE_PRIMER (
    //    ch_samplesheet
    //)

    LIMA (
        ch_samplesheet,
        primers = Channel.fromPath(params.primer_fasta_file)
    )

    //LIMA.out.p53_bam.view()
    //ch_versions = ch_versions.mix(LIMA.out.versions.first())

    //
    // MODULE: DETECT_PATTERN

    ISOSEQ3_TAG(
        LIMA.out.p53_bam,
        design = params.design
    )

    //
    // MODULE: FILTER_POLYA
    //
    ISOSEQ3_REFINE(
        ISOSEQ3_TAG.out.tag_bam,
        primers = Channel.fromPath(params.primer_fasta_file)
    )
    //
    // MODULE: SPLIT_LINKER
    //
    EXTRACT_BC(
        ISOSEQ3_REFINE.out.refine_bam
    )

    BLAST_BLASTN(
        EXTRACT_BC.out.bc8_fa,
        db = Channel.fromPath(params.bclist)
    )
    PARSE_BLASTN(
        BLAST_BLASTN.out.txt,
        bclist = Channel.fromPath(params.bclist)
    )
    CORRECT_BC(
        PARSE_BLASTN.out.txt,
        ISOSEQ3_REFINE.out.refine_bam
    )
    //
    // MODULE: DEDUP
    //
    SAMTOOLS_BC(
        CORRECT_BC.out.correct_bam
    )
    ISOSEQ3_DEDUP(
        SAMTOOLS_BC.out.sort_bam
    )
    PBMM2(
        ISOSEQ3_DEDUP.out.dedup_bam,
        reference = Channel.fromPath(params.genome_fa)
    )
    //
    // MODULE: COLLAPSE_ISOFORM
    //
    ISOSEQ3_COLLAPSE(
        PBMM2.out.map_bam
    )
    PIGEON_SORT(
        ISOSEQ3_COLLAPSE.out.gff
    )
    //
    // MODULE: GENERATE_MATRIX
    //


    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
