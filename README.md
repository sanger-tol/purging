# sanger-tol/purging

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/sanger-tol/purging)
[![GitHub Actions CI Status](https://github.com/sanger-tol/purging/actions/workflows/nf-test.yml/badge.svg)](https://github.com/sanger-tol/purging/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/sanger-tol/purging/actions/workflows/linting.yml/badge.svg)](https://github.com/sanger-tol/purging/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.2-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.5.1-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.5.1)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/sanger-tol/purging)

## Introduction

**sanger-tol/purging** is a bioinformatics pipeline for purging retained haplotypic duplication from a genome assembly.

The pipeline operates the following steps:

1. Maps reads to the primary assembly using [minimap2](https://github.com/lh3/minimap2)
2. Runs the [purge_dups](https://github.com/dfguan/purge_dups) pipeline to purge haplotypic duplication from the primary assembly.
3. If provided, concatenates the purged haplotigs to an alternate assembly.
4. Runs genome QC metrics, including [BUSCO](https://busco.ezlab.org/) and [MerquryFK](https://github.com/thegenemyers/MERQURY.FK), on the output assemblies.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

All you need to run the pipeline is a genome assembly FASTA, and PacBio HiFi reads:

```bash
nextflow run sanger-tol/purging \
   -profile <docker/singularity/.../institute> \
   -output-dir <OUTDIR>
   --primary primary.fa.gz \
   --alternate alternate.fa.gz
   --reads /path/to/reads/*.fa.gz
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

sanger-tol/purging was originally written by Jim Downie.

We thank the following people for their extensive assistance in the development of this pipeline:

- Ksenia Krashennikova
- @mahesh-panchal for the original Nextflow implementation of the purging pipeline

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- If you use sanger-tol/purging for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
