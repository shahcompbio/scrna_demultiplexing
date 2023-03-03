"""Console script for csverve."""

import click

import scrna_demultiplexing_utils.utils as utils


@click.group()
def cli():
    pass


@cli.command()
@click.option('--reference', required=True, help='CSV file path')
@click.option('--cmo_csv', required=True, help='memory for cellranger multi')
@click.option('--gex_fastq', required=True, help='cores for cellranger multi')
@click.option('--multiplex_capture_fastq', required=True, help='cores for cellranger multi')
def cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        cite_fastq,
        tempdir
):
    utils.cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        cite_fastq,
        tempdir
    )


if __name__ == "__main__":
    cli()
