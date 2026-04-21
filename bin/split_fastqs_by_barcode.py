#!/usr/bin/env python
"""
Split multiplexed 10x FASTQ files into per-sample FASTQs using a
Cell Ranger multi assignment_confidence_table.csv.

The assignment table maps cell barcodes to sample IDs. This script reads
through each FASTQ set (R1, R2, and optionally I1/I2), extracts the cell
barcode from the first 16 bases of R1, looks up the sample assignment, and
writes the read to the corresponding per-sample output FASTQ.

Works uniformly across all 10x library types (GEX, CITE, TCR, BCR) since
they share the same cell barcode structure.

Usage:
    split_fastqs_by_barcode.py \
        --assignment_table assignment_confidence_table.csv \
        --fastq_dir /path/to/multiplexed/fastqs \
        --outdir /path/to/output \
        --modality GEX \
        [--min_assignment_confidence 0.9]
"""

import csv
import gzip
import os
import sys
from collections import defaultdict
from glob import glob

import click


BARCODE_LENGTH = 16


def load_assignment_table(assignment_table_path, min_confidence=0.9):
    """
    Parse Cell Ranger's assignment_confidence_table.csv and return a
    dict mapping barcode -> sample_id.

    The CSV has columns including 'Barcodes', 'Assignment', and
    'Assignment_Probability'. Only barcodes meeting the confidence
    threshold and assigned to a real sample (not 'Unassigned' or
    'Multiplet') are included.

    Args:
        assignment_table_path: Path to assignment_confidence_table.csv
        min_confidence: Minimum assignment probability to include a barcode

    Returns:
        dict: {barcode_str: sample_id_str}
    """
    barcode_to_sample = {}

    with open(assignment_table_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            barcode = row['Barcodes'].strip()
            assignment = row['Assignment'].strip()
            confidence = float(row['Assignment_Probability'])

            # Skip unassigned, multiplets, and blanks
            if assignment in ('Unassigned', 'Multiplet', 'Blank', ''):
                continue

            if confidence >= min_confidence:
                # Remove any trailing -1 gem group suffix for matching
                barcode_clean = barcode.split('-')[0]
                barcode_to_sample[barcode_clean] = assignment

    return barcode_to_sample


def discover_fastq_sets(fastq_dir):
    """
    Discover FASTQ file sets in a directory. Groups files by their
    prefix/lane, returning sets of (R1, R2, [I1], [I2]) files.

    10x FASTQs follow the naming convention:
        {sample}_{S#}_{L###}_{R1|R2|I1|I2}_001.fastq.gz

    Returns:
        list of dicts, each with keys 'R1', 'R2', and optionally 'I1', 'I2'
    """
    r1_files = sorted(glob(os.path.join(fastq_dir, '*_R1_*.fastq.gz')))

    if not r1_files:
        raise FileNotFoundError(
            f"No R1 FASTQ files found in {fastq_dir}. "
            f"Expected files matching *_R1_*.fastq.gz"
        )

    fastq_sets = []
    for r1 in r1_files:
        fq_set = {'R1': r1}

        r2 = r1.replace('_R1_', '_R2_')
        if os.path.exists(r2):
            fq_set['R2'] = r2

        i1 = r1.replace('_R1_', '_I1_')
        if os.path.exists(i1):
            fq_set['I1'] = i1

        i2 = r1.replace('_R1_', '_I2_')
        if os.path.exists(i2):
            fq_set['I2'] = i2

        fastq_sets.append(fq_set)

    return fastq_sets


def read_fastq_record(fh):
    """Read a single FASTQ record (4 lines) from a file handle.

    Returns:
        tuple of 4 bytes lines, or None if EOF
    """
    header = fh.readline()
    if not header:
        return None
    seq = fh.readline()
    plus = fh.readline()
    qual = fh.readline()
    return (header, seq, plus, qual)


def write_fastq_record(fh, record):
    """Write a single FASTQ record (4 lines) to a file handle."""
    for line in record:
        fh.write(line)


def split_fastqs(
    assignment_table_path,
    fastq_dir,
    outdir,
    modality,
    min_confidence=0.9
):
    """
    Main splitting logic. Reads multiplexed FASTQs, filters by barcode
    assignment, and writes per-sample output FASTQs.

    Args:
        assignment_table_path: Path to assignment_confidence_table.csv
        fastq_dir: Directory containing multiplexed FASTQ files
        outdir: Output directory for per-sample FASTQs
        modality: Library type label (GEX, CITE, TCR, BCR) used in output naming
        min_confidence: Minimum barcode assignment confidence threshold
    """
    print(f"Loading assignment table from {assignment_table_path}")
    barcode_to_sample = load_assignment_table(
        assignment_table_path, min_confidence
    )
    samples = set(barcode_to_sample.values())
    print(f"Loaded {len(barcode_to_sample)} barcodes across {len(samples)} samples")
    print(f"Samples: {sorted(samples)}")

    fastq_sets = discover_fastq_sets(fastq_dir)
    print(f"Found {len(fastq_sets)} FASTQ set(s) in {fastq_dir}")

    # Create output directories per sample
    for sample in samples:
        sample_dir = os.path.join(outdir, sample, modality)
        os.makedirs(sample_dir, exist_ok=True)

    # Track counts for reporting
    counts = defaultdict(int)
    counts['total'] = 0
    counts['assigned'] = 0
    counts['unassigned'] = 0

    for fq_idx, fq_set in enumerate(fastq_sets):
        print(f"Processing FASTQ set {fq_idx + 1}/{len(fastq_sets)}")

        # Determine read types present in this set
        read_types = sorted(fq_set.keys())

        # Build output filename template from R1 name
        r1_basename = os.path.basename(fq_set['R1'])

        # Open all input file handles
        input_fhs = {}
        for rt in read_types:
            input_fhs[rt] = gzip.open(fq_set[rt], 'rt')

        # Open all output file handles (per sample, per read type)
        output_fhs = {}
        for sample in samples:
            output_fhs[sample] = {}
            for rt in read_types:
                out_name = r1_basename.replace('_R1_', f'_{rt}_')
                out_path = os.path.join(outdir, sample, modality, out_name)
                output_fhs[sample][rt] = gzip.open(out_path, 'wt')

        # Process reads
        while True:
            records = {}
            for rt in read_types:
                records[rt] = read_fastq_record(input_fhs[rt])

            # Check for EOF
            if records[read_types[0]] is None:
                break

            counts['total'] += 1

            # Extract barcode from R1 sequence (first 16 bases)
            r1_seq = records['R1'][1]  # sequence line
            barcode = r1_seq[:BARCODE_LENGTH]

            # Look up sample assignment
            sample = barcode_to_sample.get(barcode)

            if sample is None:
                counts['unassigned'] += 1
                continue

            counts['assigned'] += 1
            counts[sample] += 1

            # Write all read types for this record to the sample's output
            for rt in read_types:
                write_fastq_record(output_fhs[sample][rt], records[rt])

        # Close all file handles
        for rt in read_types:
            input_fhs[rt].close()
        for sample in samples:
            for rt in read_types:
                output_fhs[sample][rt].close()

    # Write summary report
    summary_path = os.path.join(outdir, f'{modality}_split_summary.csv')
    with open(summary_path, 'w') as f:
        f.write('metric,value\n')
        f.write(f'modality,{modality}\n')
        f.write(f'total_reads,{counts["total"]}\n')
        f.write(f'assigned_reads,{counts["assigned"]}\n')
        f.write(f'unassigned_reads,{counts["unassigned"]}\n')
        f.write(f'min_confidence_threshold,{min_confidence}\n')
        for sample in sorted(samples):
            f.write(f'reads_{sample},{counts[sample]}\n')

    print(f"\nSplitting complete:")
    print(f"  Total reads:      {counts['total']}")
    print(f"  Assigned reads:   {counts['assigned']}")
    print(f"  Unassigned reads: {counts['unassigned']}")
    for sample in sorted(samples):
        print(f"  {sample}: {counts[sample]} reads")
    print(f"\nSummary written to {summary_path}")


@click.command()
@click.option(
    '--assignment_table', required=True,
    help='Path to Cell Ranger assignment_confidence_table.csv'
)
@click.option(
    '--fastq_dir', required=True,
    help='Directory containing multiplexed FASTQ files to split'
)
@click.option(
    '--outdir', required=True,
    help='Output directory for per-sample FASTQs'
)
@click.option(
    '--modality', required=True,
    type=click.Choice(['GEX', 'CITE', 'TCR', 'BCR'], case_sensitive=False),
    help='Library type (GEX, CITE, TCR, BCR)'
)
@click.option(
    '--min_assignment_confidence', default=0.9, type=float,
    help='Minimum assignment confidence to include a barcode (default: 0.9)'
)
def main(assignment_table, fastq_dir, outdir, modality, min_assignment_confidence):
    """Split multiplexed 10x FASTQs into per-sample FASTQs by cell barcode."""
    split_fastqs(
        assignment_table_path=assignment_table,
        fastq_dir=fastq_dir,
        outdir=outdir,
        modality=modality.upper(),
        min_confidence=min_assignment_confidence,
    )


if __name__ == '__main__':
    main()
