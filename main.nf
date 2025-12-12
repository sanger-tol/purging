#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    sanger-tol/purging
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/sanger-tol/purging
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PURGING                 } from './workflows/purging'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_purging_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_purging_pipeline'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow SANGERTOL_PURGING {

    take:
    assembly
    reads
    fastk
    val_reads_per_chunk
    val_busco_lineage
    val_busco_lineage_directory

    main:

    //
    // WORKFLOW: Run pipeline
    //
    PURGING (
        assembly,
        reads,
        fastk,
        val_reads_per_chunk,
        val_busco_lineage,
        val_busco_lineage_directory
    )

    emit:
    primary                    = PURGING.out.primary
    alternate                  = PURGING.out.alternate
    haplotigs                  = PURGING.out.haplotigs
    purgedups_splitfa          = PURGING.out.purgedups_splitfa
    purgedups_splitfa_self_paf = PURGING.out.purgedups_splitfa_self_paf
    purgedups_pbcstat_hist     = PURGING.out.purgedups_pbcstat_hist
    purgedups_pbcstat_basecov  = PURGING.out.purgedups_pbcstat_basecov
    purgedups_calcuts_cutoffs  = PURGING.out.purgedups_calcuts_cutoffs
    purgedups_calcuts_log      = PURGING.out.purgedups_calcuts_log
    purgedups_histplot         = PURGING.out.purgedups_histplot
    purgedups_bed              = PURGING.out.purgedups_bed
    purgedups_log              = PURGING.out.purgedups_log
    primary_reads_paf          = PURGING.out.primary_reads_paf
    asmstats                   = PURGING.out.asmstats
    gfastats                   = PURGING.out.gfastats
    busco_summary_txt          = PURGING.out.busco_summary_txt
    busco_summary_json         = PURGING.out.busco_summary_json
    busco_batch_summary        = PURGING.out.busco_batch_summary
    busco_log                  = PURGING.out.busco_log
    busco_directory            = PURGING.out.busco_directory
    merqury_qv                 = PURGING.out.merqury_qv
    merqury_completeness       = PURGING.out.merqury_completeness
    merqury_phased_stats       = PURGING.out.merqury_phased_stats
    merqury_images             = PURGING.out.merqury_images
    versions                   = PURGING.out.versions
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.help,
        params.help_full,
        params.show_hidden,
        params.primary,
        params.alternate,
        params.reads,
        params.fastk,
        params.genomescope_model,
        params.coverage,
        params.cutoffs
    )

    //
    // WORKFLOW: Run main workflow
    //
    SANGERTOL_PURGING (
        PIPELINE_INITIALISATION.out.assembly,
        PIPELINE_INITIALISATION.out.reads,
        PIPELINE_INITIALISATION.out.fastk,
        params.mapping_reads_per_chunk,
        params.busco_lineage,
        params.busco_lineage_directory
    )

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
    )

    publish:
    purged_primary             = SANGERTOL_PURGING.out.primary
    purged_alternate           = SANGERTOL_PURGING.out.alternate
    purged_haplotigs           = SANGERTOL_PURGING.out.haplotigs

    purgedups_pbcstat_hist     = SANGERTOL_PURGING.out.purgedups_pbcstat_hist
    purgedups_pbcstat_basecov  = SANGERTOL_PURGING.out.purgedups_pbcstat_basecov
    purgedups_calcuts_cutoffs  = SANGERTOL_PURGING.out.purgedups_calcuts_cutoffs
    purgedups_calcuts_log      = SANGERTOL_PURGING.out.purgedups_calcuts_log
    purgedups_histplot         = SANGERTOL_PURGING.out.purgedups_histplot
    primary_reads_paf          = SANGERTOL_PURGING.out.primary_reads_paf

    purgedups_splitfa_self_paf = SANGERTOL_PURGING.out.purgedups_splitfa_self_paf

    purgedups_bed              = SANGERTOL_PURGING.out.purgedups_bed
    purgedups_log              = SANGERTOL_PURGING.out.purgedups_log

    asmstats                   = SANGERTOL_PURGING.out.asmstats
    gfastats                   = SANGERTOL_PURGING.out.gfastats

    busco_batch_summary        = SANGERTOL_PURGING.out.busco_batch_summary
    busco_summary_txt          = SANGERTOL_PURGING.out.busco_summary_txt
    busco_summary_json         = SANGERTOL_PURGING.out.busco_summary_json
    busco_log                  = SANGERTOL_PURGING.out.busco_log
    busco_directory            = SANGERTOL_PURGING.out.busco_directory

    merqury_qv                 = SANGERTOL_PURGING.out.merqury_qv
    merqury_completeness       = SANGERTOL_PURGING.out.merqury_completeness
    merqury_phased_stats       = SANGERTOL_PURGING.out.merqury_phased_stats
    merqury_images             = SANGERTOL_PURGING.out.merqury_images

    versions                   = SANGERTOL_PURGING.out.versions
}

output {
    purged_primary {
        path '.'
    }
    purged_alternate {
        path '.'
    }
    purged_haplotigs {
        path 'seqs/'
    }
    primary_reads_paf {
        path 'coverage'
        enabled params.publish_reads_paf
    }
    purgedups_pbcstat_hist {
        path 'coverage'
    }
    purgedups_pbcstat_basecov {
        path 'coverage'
    }
    purgedups_calcuts_cutoffs {
        path 'coverage'
    }
    purgedups_calcuts_log {
        path 'coverage'
    }
    purgedups_histplot {
        path 'coverage'
    }
    purgedups_splitfa_self_paf {
        path 'split_aln'
    }
    purgedups_bed {
        path 'split_aln'
    }
    purgedups_log {
        path 'split_aln'
    }
    asmstats {
        path '.'
    }
    gfastats {
        path '.'
    }
    busco_batch_summary {
        path "asm.busco.${params.busco_lineage}"
    }
    busco_summary_txt {
        path "asm.busco.${params.busco_lineage}"
    }
    busco_summary_json {
        path "asm.busco.${params.busco_lineage}"
    }
    busco_log {
        path "asm.busco.${params.busco_lineage}"
    }
    busco_directory {
        path "asm.busco.${params.busco_lineage}"
    }
    merqury_qv {
        path 'asm.merquryfk'
    }
    merqury_completeness {
        path 'asm.merquryfk'
    }
    merqury_phased_stats {
        path 'asm.merquryfk'
    }
    merqury_images {
        path 'asm.merquryfk'
    }
    versions {
        path 'pipeline_info/'
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
