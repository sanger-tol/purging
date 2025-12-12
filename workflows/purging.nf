/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap                } from 'plugin/nf-schema'
include { softwareVersionsToYAML          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText          } from '../subworkflows/local/utils_nfcore_purging_pipeline'

include { GUNZIP                          } from '../modules/nf-core/gunzip/main'
include { TABIX_BGZIP as BGZIP_ASSEMBLIES } from '../modules/nf-core/tabix/bgzip/main'

include { FASTA_PURGE_RETAINED_HAPLOTYPE  } from '../subworkflows/sanger-tol/fasta_purge_retained_haplotype/main'
include { GENOME_STATISTICS               } from '../subworkflows/sanger-tol/genome_statistics/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PURGING {

    take:
    ch_assembly                 // channel: [meta, pri, alt]
    ch_reads                    // channel: [meta, reads fasta]
    ch_fastk                    // channel: [meta, fk_hist, fk_ktab]
    val_reads_per_chunk         // int: number of reads to map per chunk
    val_busco_lineage           // string: busco lineage to use for statistics
    val_busco_lineage_directory // file: path to busco lineage directory

    main:
    ch_versions = channel.empty()

    //
    // Module: Unzip assemblies if gzipped so we only operate on unzipped asms
    //
    ch_assemblies_to_gunzip = ch_assembly
        .flatMap { meta, pri, alt ->
            [[meta + [_hap: "pri"], pri], [meta + [_hap: "alt"], alt]]
        }
        .branch { _meta, asm ->
            unzip: asm.getExtension() == "gz"
            asis: true
        }

    GUNZIP(ch_assemblies_to_gunzip.unzip)
    ch_versions = ch_versions.mix(GUNZIP.out.versions)

    ch_unzipped_assemblies_split = GUNZIP.out.gunzip
        .mix(ch_assemblies_to_gunzip.asis)
        .branch { meta, asm ->
            pri: meta._hap == "pri"
                return [ meta - meta.subMap("_hap"), asm ]
            alt: meta._hap == "alt"
                return [ meta - meta.subMap("_hap"), asm ]
        }

    ch_unzipped_assemblies = ch_unzipped_assemblies_split.pri
        .join(ch_unzipped_assemblies_split.alt)

    //
    // Subworkflow: purge retained haplotype from primary assembly
    //
    FASTA_PURGE_RETAINED_HAPLOTYPE(
        ch_unzipped_assemblies,
        ch_reads,
        val_reads_per_chunk
    )
    ch_versions = ch_versions.mix(FASTA_PURGE_RETAINED_HAPLOTYPE.out.versions)

    //
    // Logic: bgzip assemblies
    //
    ch_assemblies_to_bgzip = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purged_assemblies
        .flatMap { meta, pri, alt ->
            [
                [meta + [_hap: "pri"], pri],
                [meta + [_hap: "alt"], alt]
            ]
        }
        .mix(
            FASTA_PURGE_RETAINED_HAPLOTYPE.out.purged_haplotigs.map { meta, tigs -> [meta + [_hap: "tigs"], tigs ] }
        )

    BGZIP_ASSEMBLIES(ch_assemblies_to_bgzip)
    ch_versions = ch_versions.mix(BGZIP_ASSEMBLIES.out.versions)

    ch_purged_primary = BGZIP_ASSEMBLIES.out.output
        .filter { meta, asm -> meta._hap == "pri" }
        .map { meta, asm -> [ meta - meta.subMap("_hap"), asm ] }

    ch_concat_alt = BGZIP_ASSEMBLIES.out.output
        .filter { meta, asm -> meta._hap == "alt" }
        .map { meta, asm -> [ meta - meta.subMap("_hap"), asm ] }

    ch_purged_haplotigs = BGZIP_ASSEMBLIES.out.output
        .filter { meta, asm -> meta._hap == "tigs" }
        .map { meta, asm -> [ meta - meta.subMap("_hap"), asm ] }

    //
    // Subworkflow: calculate genome statistics of purged assemblies
    //
    GENOME_STATISTICS(
        ch_purged_primary.join(ch_concat_alt, by: 0),
        ch_fastk,
        channel.empty(),
        channel.empty(),
        val_busco_lineage ?: channel.empty(),
        val_busco_lineage_directory
    )
    ch_versions = ch_versions.mix(GENOME_STATISTICS.out.versions)

    //
    // Collate and save software versions
    //
    def topic_versions = Channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            name:  'purging_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    emit:
    primary                    = ch_purged_primary
    alternate                  = ch_concat_alt
    haplotigs                  = ch_purged_haplotigs
    purgedups_splitfa          = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_splitfa
    purgedups_splitfa_self_paf = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_splitfa_self_paf
    purgedups_pbcstat_hist     = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_pbcstat_hist
    purgedups_pbcstat_basecov  = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_pbcstat_basecov
    purgedups_calcuts_cutoffs  = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_calcuts_cutoffs
    purgedups_calcuts_log      = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_calcuts_log
    purgedups_histplot         = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_histplot
    purgedups_bed              = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_bed
    purgedups_log              = FASTA_PURGE_RETAINED_HAPLOTYPE.out.purgedups_log
    primary_reads_paf          = FASTA_PURGE_RETAINED_HAPLOTYPE.out.primary_reads_paf
    asmstats                   = GENOME_STATISTICS.out.asmstats
    gfastats                   = GENOME_STATISTICS.out.gfastats
    busco_summary_txt          = GENOME_STATISTICS.out.busco_summary_txt
    busco_summary_json         = GENOME_STATISTICS.out.busco_summary_json
    busco_batch_summary        = GENOME_STATISTICS.out.busco_batch_summary
    busco_log                  = GENOME_STATISTICS.out.busco_log
    busco_directory            = GENOME_STATISTICS.out.busco_directory
    merqury_qv                 = GENOME_STATISTICS.out.merqury_qv
    merqury_completeness       = GENOME_STATISTICS.out.merqury_completeness
    merqury_phased_stats       = GENOME_STATISTICS.out.merqury_phased_stats
    merqury_images             = GENOME_STATISTICS.out.merqury_images
    versions                   = ch_collated_versions

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
