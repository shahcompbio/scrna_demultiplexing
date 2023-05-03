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
@click.option('--cite_fastq', required=True, help='cores for cellranger multi')
@click.option('--cite_id', required=True, help='cores for cellranger multi')
@click.option('--outdir', required=True, help='cores for cellranger multi')
@click.option('--tar_output', required=True, help='cores for cellranger multi')
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
        cite_fastq,
        cite_id,
        outdir,
        tar_output,
        tempdir,
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
        cite_fastq,
        cite_id,
        outdir,
        tar_output,
        tempdir,
        numcores=numcores,
        mempercore=mempercore,
        maxjobs=maxjobs,
        jobmode=jobmode
    )


@cli.command()
@click.option('--reference', required=True, help='CSV file path')
@click.option('--feature_reference', required=True, help='CSV file path')
@click.option('--vdj_reference', required=True, help='CSV file path')
@click.option('--gex_fastq', required=True, help='cores for cellranger multi')
@click.option('--gex_id', required=True, help='cores for cellranger multi')
@click.option('--gex_metrics', required=True, help='cores for cellranger multi')
@click.option('--tcr_fastq', required=True, help='cores for cellranger multi')
@click.option('--tcr_id', required=True, help='cores for cellranger multi')
@click.option('--cite_fastq', required=True, help='cores for cellranger multi')
@click.option('--cite_id', required=True, help='cores for cellranger multi')
@click.option('--tar_output', required=True, help='cores for cellranger multi')
@click.option('--tempdir', required=True, help='cores for cellranger multi')
@click.option('--bcr_fastq', help='cores for cellranger multi')
@click.option('--bcr_id', help='cores for cellranger multi')
@click.option('--numcores', required=True, help='cores for cellranger multi')
@click.option('--mempercore', required=True, help='cores for cellranger multi')
@click.option('--maxjobs', required=True, help='cores for cellranger multi')
@click.option('--jobmode', required=True, help='cores for cellranger multi')
def cellranger_multi_vdj(
        reference,
        feature_reference,
        vdj_reference,
        gex_fastq,
        gex_id,
        gex_metrics,
        tcr_fastq,
        tcr_id,
        cite_fastq,
        cite_id,
        tar_output,
        tempdir,
        bcr_fastq=None,
        bcr_id=None,
        numcores=16,
        mempercore=10,
        maxjobs=200,
        jobmode='local'
):
    utils.cellranger_multi_vdj(
        reference,
        feature_reference,
        vdj_reference,
        gex_fastq,
        gex_id,
        gex_metrics,
        tcr_fastq,
        tcr_id,
        cite_fastq,
        cite_id,
        tar_output,
        tempdir,
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
