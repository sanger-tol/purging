/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap                } from 'plugin/nf-schema'
include { softwareVersionsToYAML          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText          } from '../subworkflows/local/utils_nfcore_purging_pipeline'

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
    // Subworkflow: purge retained haplotype from primary assembly
    //
    FASTA_PURGE_RETAINED_HAPLOTYPE(
        ch_assembly,
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
            FASTA_PURGE_RETAINED_HAPLOTYPE.out.haplotigs.map { meta, tigs -> [meta + [_hap: "tigs"], tigs ] }
        )

    BGZIP_ASSEMBLIES(ch_assemblies_to_bgzip)
    ch_versions = ch_versions.mix(BGZIP_ASSEMBLIES.out.versions)


    ch_purged_primary = BGZIP_ASSEMBLIES.out.output
        .filter { meta._hap == "pri" }
        .map { meta, asm -> [ meta - meta.subMap("_hap"), asm ] }

    ch_concat_alt = BGZIP_ASSEMBLIES.out.output
        .filter { meta._hap == "alt" }
        .map { meta, asm -> [ meta - meta.subMap("_hap"), asm ] }

    ch_purged_haplotigs = BGZIP_ASSEMBLIES.out.output
        .filter { meta._hap == "tigs" }
        .map { meta, asm -> [ meta - meta.subMap("_hap"), asm ] }

    //
    // Subworkflow: calculate genome statistics of purged assemblies
    //
    GENOME_STATISTICS(
        ch_purged_primary.join(ch_concat_alt, by: 0),
        ch_fastk,
        [[:], []],
        [[:], []],
        val_busco_lineage,
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
            storeDir: "${params.outdir}/pipeline_info",
            name:  'purging_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
