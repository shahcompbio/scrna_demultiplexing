"""Console script for csverve."""

import click

import scrna_demultiplexing_utils.utils as utils


@click.group()
def cli():
    pass


@cli.command()
@click.option('--reference', required=True, help='CSV file path')
@click.option('--meta_yaml', required=True, help='memory for cellranger multi')
@click.option('--gex_fastq', required=True, help='cores for cellranger multi')
@click.option('--gex_id', required=True, help='cores for cellranger multi')
@click.option('--cite_fastq', help='cores for cellranger multi')
@click.option('--cite_id', help='cores for cellranger multi')
@click.option('--outdir', required=True, help='cores for cellranger multi')
@click.option('--tempdir', required=True, help='cores for cellranger multi')
@click.option('--numcores', required=True, help='cores for cellranger multi')
@click.option('--mempercore', required=True, help='cores for cellranger multi')
@click.option('--maxjobs', required=True, help='cores for cellranger multi')
@click.option('--jobmode', required=True, help='cores for cellranger multi')
def cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        gex_id,
        outdir,
        tempdir,
        cite_fastq=None,
        cite_id=None,
        numcores=16,
        mempercore=10,
        maxjobs=200,
        jobmode='local'
):
    utils.cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        gex_id,
        outdir,
        tempdir,
        cite_fastq=cite_fastq,
        cite_identifier=cite_id,
        numcores=numcores,
        mempercore=mempercore,
        maxjobs=maxjobs,
        jobmode=jobmode
    )


@cli.command()
@click.option('--reference', required=True, help='CSV file path')
@click.option('--vdj_reference', required=True, help='CSV file path')
@click.option('--gex_fastq', required=True, help='cores for cellranger multi')
@click.option('--gex_id', required=True, help='cores for cellranger multi')
@click.option('--gex_metrics', required=True, help='cores for cellranger multi')
@click.option('--tcr_fastq',  help='cores for cellranger multi')
@click.option('--tcr_id',  help='cores for cellranger multi')
@click.option('--cite_fastq',  help='cores for cellranger multi')
@click.option('--cite_id', help='cores for cellranger multi')
@click.option('--meta_yaml', required=True, help='CSV file path')
@click.option('--output', required=True, help='cores for cellranger multi')
@click.option('--tempdir', required=True, help='cores for cellranger multi')
@click.option('--sample_id', required=True, help='cores for cellranger multi')
@click.option('--bcr_fastq', help='cores for cellranger multi')
@click.option('--bcr_id', help='cores for cellranger multi')
@click.option('--numcores', required=True, help='cores for cellranger multi')
@click.option('--mempercore', required=True, help='cores for cellranger multi')
@click.option('--maxjobs', required=True, help='cores for cellranger multi')
@click.option('--jobmode', required=True, help='cores for cellranger multi')
def cellranger_multi_vdj(
        reference,
        vdj_reference,
        gex_fastq,
        gex_id,
        gex_metrics,
        output,
        meta_yaml,
        tempdir,
        sample_id,
        tcr_fastq=None,
        tcr_id=None,
        cite_fastq=None,
        cite_id=None,
        bcr_fastq=None,
        bcr_id=None,
        numcores=16,
        mempercore=10,
        maxjobs=200,
        jobmode='local'
):
    utils.cellranger_multi_vdj(
        reference,
        vdj_reference,
        gex_fastq,
        gex_id,
        gex_metrics,
        output,
        meta_yaml,
        tempdir,
        sample_id,
        tcr_fastq=tcr_fastq,
        tcr_identifier=tcr_id,
        cite_fastq=cite_fastq,
        cite_identifier=cite_id,
        bcr_fastq=bcr_fastq,
        bcr_identifier=bcr_id,
        numcores=numcores,
        mempercore=mempercore,
        maxjobs=maxjobs,
        jobmode=jobmode
    )


@cli.command()
@click.option('--bam_file', required=True, help='CSV file path')
@click.option('--metrics', required=True, help='CSV file path')
@click.option('--outdir', required=True, help='CSV file path')
@click.option('--tempdir', required=True, help='CSV file path')
def bam_to_fastq(bam_file, metrics, outdir, tempdir):
    utils.bam_to_fastq(
        bam_file,
        metrics,
        outdir,
        tempdir
    )


if __name__ == "__main__":
    cli()
