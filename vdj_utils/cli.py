"""Console script for csverve."""

import click

import vdj_utils.utils as utils


@click.group()
def cli():
    pass


@cli.command()
@click.option('--csv', required=True, help='CSV file path')
@click.option('--memory', required=True, help='memory for cellranger multi')
@click.option('--cores', required=True, help='cores for cellranger multi')
def cellranger_multi(
        csv_file,
        tempdir,
        memory,
        cores,
):
    utils.cellranger_multi(
        csv_file,
        tempdir,
        memory,
        cores
    )


if __name__ == "__main__":
    cli()
