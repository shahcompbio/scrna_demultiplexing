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
@click.option('--tempdir', required=True, help='cores for cellranger multi')

def cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        gex_id,
        cite_fastq,
        cite_id,
        outdir,
        tempdir
):
    utils.cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        gex_id,
        cite_fastq,
        cite_id,
        outdir,
        tempdir
    )


if __name__ == "__main__":
    cli()
