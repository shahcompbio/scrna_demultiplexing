# Demultiplexing Documentation

This document provides a comprehensive explanation of how sample demultiplexing works in this pipeline, including background on multiplexed samples, hashtag oligos (HTOs), the barcode-based FASTQ splitting approach, and how to use the available pipeline options.

---

## Table of Contents

1. [Background: What Are Multiplexed Samples?](#background-what-are-multiplexed-samples)
2. [Hashtag Oligos (HTOs) and Sample-to-Hashtag Mapping](#hashtag-oligos-htos-and-sample-to-hashtag-mapping)
3. [Library Types (Modalities)](#library-types-modalities)
4. [How Demultiplexing Works in This Pipeline](#how-demultiplexing-works-in-this-pipeline)
5. [Barcode-Based FASTQ Splitting](#barcode-based-fastq-splitting)
6. [Pipeline Options](#pipeline-options)
7. [Output Structure](#output-structure)
8. [The meta.yaml File](#the-metayaml-file)
9. [End-to-End Pipeline Flow](#end-to-end-pipeline-flow)

---

## Background: What Are Multiplexed Samples?

In single-cell RNA sequencing (scRNA-seq) experiments, **multiplexing** refers to pooling cells from multiple biological samples (e.g., different donors, conditions, or timepoints) into a single sequencing run. This reduces per-sample costs, minimizes batch effects, and increases throughput.

The challenge is that after sequencing, all reads from all samples are mixed together in a single set of FASTQ files. **Demultiplexing** is the process of assigning each cell (and therefore each sequencing read) back to its original sample.

### Why Multiplex?

- **Cost efficiency**: One 10x Chromium lane processes thousands of cells; pooling samples shares that cost.
- **Reduced batch effects**: Samples processed together eliminate lane-to-lane technical variation.
- **Doublet detection**: Cells with hashtags from multiple samples can be identified as doublets.

---

## Hashtag Oligos (HTOs) and Sample-to-Hashtag Mapping

To enable demultiplexing, each sample's cells are labeled with a unique **Hashtag Oligo (HTO)** before pooling. HTOs are antibody-conjugated oligonucleotides that bind to ubiquitous cell-surface proteins. Each HTO carries a unique barcode sequence.

### How It Works

1. **Labeling**: Cells from Sample A are incubated with HTO-1, cells from Sample B with HTO-2, etc.
2. **Pooling**: Labeled cells are combined into a single suspension.
3. **Sequencing**: The pooled cells are loaded onto a 10x Chromium chip. During library preparation, HTO barcodes are captured alongside gene expression (GEX) and other modality reads.
4. **Assignment**: After sequencing, Cell Ranger `multi` reads the HTO signals and assigns each cell barcode to a sample based on which HTO is most abundant.

### Sample-to-Hashtag Mapping Example

In the `meta.yaml` file, the mapping is defined as:

```yaml
meta:
  hashtag:
    Hash-tag1:
      sample_id: Donor1_healthy
      sequence: GTCAACTCTTTAGCG
    Hash-tag2:
      sample_id: Donor2_healthy
      sequence: TGATGGCCTATTGGG
    Hash-tag3:
      sample_id: Donor3_ALLpatient
      sequence: TTCCGCCTCTCTTTG
    Hash-tag4:
      sample_id: Donor4_ALLpatient
      sequence: AGTAAGTTCAGCGTA
```

Each hashtag entry specifies:
- **Hashtag ID** (e.g., `Hash-tag1`): The identifier for the HTO barcode.
- **sample_id** (e.g., `Donor1_healthy`): The biological sample this HTO represents.
- **sequence** (e.g., `GTCAACTCTTTAGCG`): The unique oligonucleotide sequence of the HTO.

---

## Library Types (Modalities)

A multiplexed 10x experiment can include multiple library types, all sharing the same cell barcodes:

| Modality | Description | FASTQ Content |
|----------|-------------|---------------|
| **GEX** (Gene Expression) | mRNA transcriptome | Gene expression reads |
| **CITE** (CITEseq / Antibody Capture) | Protein-level measurements via antibody-conjugated oligos | Antibody barcode reads |
| **HTO** (Hashtag Oligo) | Sample identity labels (often sequenced with CITE) | Hashtag barcode reads |
| **TCR** (VDJ-T) | T-cell receptor sequences | TCR recombination reads |
| **BCR** (VDJ-B) | B-cell receptor sequences | BCR recombination reads |

**Key insight**: All modalities share the same **cell barcode** (first 16bp of R1 in 10x 3'/5' chemistry). This means a barcode-to-sample assignment derived from HTO data can be applied to split FASTQs from *any* modality.

---

## How Demultiplexing Works in This Pipeline

### Step 1: Cell Ranger Multi (CELLRANGER_DEMULTIPLEX)

The pipeline runs `cellranger multi` with the GEX and HTO/CITE FASTQs. Cell Ranger:

1. Aligns GEX reads to the reference genome.
2. Counts HTO barcodes per cell.
3. Uses a statistical model to assign each cell barcode to a sample (or flag it as a multiplet/unassigned).
4. Produces an **assignment_confidence_table.csv** mapping every cell barcode to its sample with a confidence score.

### Step 2: BAM-to-FASTQ Conversion (CELLRANGER_BAMTOFASTQ)

For the per-sample analysis step, Cell Ranger's per-sample BAMs (GEX only) are converted back to FASTQs using `bamtofastq`. These GEX FASTQs are then used by `CELLRANGER_PER_SAMPLE` along with the original (unsplit) TCR/BCR/CITE FASTQs.

### Step 3: Barcode-Based FASTQ Splitting (SPLIT_FASTQS_BY_BARCODE) — NEW

In addition to the BAM-to-FASTQ approach, the pipeline now splits the **original multiplexed FASTQs** for all modalities into per-sample FASTQs using the assignment table. This approach:

- **Is lossless**: Preserves the exact original FASTQ reads (quality scores, unmapped reads, etc.).
- **Works for all modalities**: GEX, CITE, TCR, and BCR are all split using the same barcode lookup.
- **Is faster**: No BAM decompression; just a single-pass FASTQ filter.

---

## Barcode-Based FASTQ Splitting

### How It Works

```
                      cellranger multi
GEX + HTO FASTQs ──────────────────────► assignment_confidence_table.csv
                                                    │
                                          barcode → sample_id
                                                    │
              ┌──────────────┬──────────────┬───────┴───────┐
              ▼              ▼              ▼               ▼
        GEX FASTQs     CITE FASTQs    TCR FASTQs      BCR FASTQs
        (filter R1     (filter R1     (filter R1      (filter R1
         barcode)       barcode)       barcode)        barcode)
              │              │              │               │
              ▼              ▼              ▼               ▼
        per-sample     per-sample     per-sample      per-sample
        GEX FASTQs     CITE FASTQs    TCR FASTQs      BCR FASTQs
```

### The Algorithm

For each FASTQ set (R1 + R2 + optional I1/I2):

1. Read a FASTQ record (4 lines) from each read file simultaneously.
2. Extract the **cell barcode** from the first 16 bases of the R1 sequence.
3. Look up the barcode in the assignment table.
4. If the barcode is assigned to a sample with sufficient confidence, write all reads (R1, R2, I1, I2) to that sample's output files.
5. If the barcode is unassigned, a multiplet, or below the confidence threshold, discard the read.

### Cell Barcode Structure

In 10x Chromium 3' and 5' chemistries, R1 contains:
```
[16bp cell barcode][10-12bp UMI][remaining sequence]
```

The cell barcode is always the first 16 bases. This is consistent across GEX, CITE, TCR, and BCR libraries because they all use the same 10x Gel Bead barcode.

### Assignment Confidence

Cell Ranger assigns a confidence probability to each barcode's sample assignment. The pipeline uses a configurable threshold (`--min_assignment_confidence`, default 0.9) to filter out low-confidence assignments. Barcodes below this threshold are treated as unassigned.

### What Gets Filtered Out

- **Unassigned barcodes**: Cell barcodes that Cell Ranger could not confidently assign to any sample.
- **Multiplets**: Cell barcodes with signal from multiple HTOs (likely doublets from different samples).
- **Low-confidence assignments**: Barcodes assigned below the confidence threshold.
- **Non-cellular barcodes**: Reads with barcodes not in the assignment table (ambient RNA, empty droplets).

---

## Pipeline Options

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--save_demux_fastqs` | `false` | Publish per-sample demultiplexed FASTQs to the output directory |
| `--demux_only` | `false` | Stop after demultiplexing; skip the per-sample Cell Ranger analysis |
| `--min_assignment_confidence` | `0.9` | Minimum confidence threshold for barcode-to-sample assignment |

### Usage Examples

**Full pipeline (default)**:
```bash
nextflow run shahcompbio/scrna_demultiplexing \
  -profile singularity \
  --output_dir outputs \
  --meta_yaml meta.yaml \
  --gex_fastq /path/to/gex \
  --gex_id GEX_SAMPLE_ID \
  --cite_fastq /path/to/cite \
  --cite_id CITE_SAMPLE_ID \
  --reference /path/to/GRCh38 \
  --vdj_reference /path/to/vdj_ref \
  --sample_id SAMP123
```

**Demultiplex only (skip per-sample analysis), saving all per-sample FASTQs**:
```bash
nextflow run shahcompbio/scrna_demultiplexing \
  -profile singularity \
  --output_dir outputs \
  --demux_only true \
  --save_demux_fastqs true \
  --meta_yaml meta.yaml \
  --gex_fastq /path/to/gex \
  --gex_id GEX_SAMPLE_ID \
  --cite_fastq /path/to/cite \
  --cite_id CITE_SAMPLE_ID \
  --reference /path/to/GRCh38 \
  --vdj_reference /path/to/vdj_ref \
  --sample_id SAMP123
```

**With custom confidence threshold**:
```bash
nextflow run shahcompbio/scrna_demultiplexing \
  --min_assignment_confidence 0.8 \
  ...
```

---

## Output Structure

When `--save_demux_fastqs true` is set, the per-sample split FASTQs are published to:

```
outputs/
└── demux_fastqs/
    ├── Donor1_healthy/
    │   ├── GEX/
    │   │   ├── sample_S1_L001_R1_001.fastq.gz
    │   │   └── sample_S1_L001_R2_001.fastq.gz
    │   ├── CITE/
    │   │   ├── sample_S1_L001_R1_001.fastq.gz
    │   │   └── sample_S1_L001_R2_001.fastq.gz
    │   ├── TCR/
    │   │   ├── sample_S1_L001_R1_001.fastq.gz
    │   │   └── sample_S1_L001_R2_001.fastq.gz
    │   └── BCR/
    │       ├── sample_S1_L001_R1_001.fastq.gz
    │       └── sample_S1_L001_R2_001.fastq.gz
    ├── Donor2_healthy/
    │   └── ...
    ├── GEX_split_summary.csv
    ├── CITE_split_summary.csv
    ├── TCR_split_summary.csv
    └── BCR_split_summary.csv
```

Each `*_split_summary.csv` contains:
- Total reads processed
- Number of assigned vs. unassigned reads
- Per-sample read counts
- The confidence threshold used

---

## The meta.yaml File

The `meta.yaml` file is the central configuration that defines the experimental setup. It tells the pipeline which hashtags were used, what samples they correspond to, and optionally which CITEseq antibodies were included.

### Full Example

```yaml
meta:
  hashtag:
    Hash-tag1:
      sample_id: Donor1_healthy
      sequence: GTCAACTCTTTAGCG
    Hash-tag2:
      sample_id: Donor2_healthy
      sequence: TGATGGCCTATTGGG
    Hash-tag3:
      sample_id: Donor3_ALLpatient
      sequence: TTCCGCCTCTCTTTG
    Hash-tag4:
      sample_id: Donor4_ALLpatient
      sequence: AGTAAGTTCAGCGTA
  citeseq:
    CD86:
      protein: anti-human_CD86
      sequence: GTCTTTGTCAGTGCA
    CD274:
      protein: anti-human_CD274_B7-H1_PD-L1
      sequence: GTTGTCCGACAATAC
```

### Key Sections

- **`meta.hashtag`**: Required for multiplexed samples. Maps HTO names → sample IDs and barcode sequences. If this section is present, the pipeline uses the demultiplexing path.
- **`meta.citeseq`**: Optional. Defines CITEseq antibody panel with protein names and barcode sequences.

### How the Pipeline Uses meta.yaml

1. **`CELLRANGER_IS_MULTIPLEXED`**: Checks if `hashtag` is present → determines multiplexed vs. non-multiplexed path.
2. **`CELLRANGER_DEMULTIPLEX`**: Uses the hashtag sequences to build Cell Ranger's CMO reference and the sample-to-hashtag mapping for the `[samples]` section of the multi config CSV.
3. **`SPLIT_FASTQS_BY_BARCODE`**: Indirectly uses it — Cell Ranger's assignment table (derived from the hashtag info) drives the splitting.

---

## End-to-End Pipeline Flow

### Multiplexed Path (HTO present)

```
1. CELLRANGER_IS_MULTIPLEXED
   └─ Detects hashtags in meta.yaml → mode = "multiplexed"

2. CELLRANGER_DEMULTIPLEX
   ├─ Input: GEX FASTQs + CITE/HTO FASTQs + reference + meta.yaml
   ├─ Runs: cellranger multi
   ├─ Output: per_sample_outs/* (per-sample BAMs, metrics, etc.)
   └─ Output: assignment_confidence_table.csv (barcode → sample mapping)

3. CELLRANGER_BAMTOFASTQ (one per sample from step 2)
   ├─ Input: per-sample directory with BAM
   ├─ Runs: bamtofastq on GEX BAM
   └─ Output: per-sample GEX FASTQs + metrics.csv

4. SPLIT_FASTQS_BY_BARCODE (one per modality: GEX, CITE, TCR, BCR)
   ├─ Input: assignment_confidence_table.csv + original multiplexed FASTQs
   ├─ Runs: barcode-based filtering of original FASTQs
   └─ Output: per-sample FASTQs for that modality (all samples)

5. CELLRANGER_PER_SAMPLE (skipped if --demux_only)
   ├─ Input: demuxed GEX FASTQs (from step 3) + original TCR/BCR/CITE FASTQs
   ├─ Runs: cellranger multi per sample
   └─ Output: final per-sample Cell Ranger results
```

### Non-Multiplexed Path (no HTO)

```
1. CELLRANGER_IS_MULTIPLEXED
   └─ No hashtags in meta.yaml → mode = "non-multiplexed"

2. CELLRANGER_NON_MULTIPLEXED
   ├─ Input: all FASTQs + references + meta.yaml
   ├─ Runs: cellranger multi (single sample)
   └─ Output: Cell Ranger results directly
```

### Important Notes

- **Steps 3 and 4 serve different purposes**: Step 3 (BAM-to-FASTQ) produces GEX FASTQs used by the per-sample Cell Ranger run (step 5). Step 4 (barcode splitting) produces per-sample FASTQs for *all modalities* as publishable outputs. They run in parallel.
- **Step 4 only runs on the multiplexed path**: Non-multiplexed samples don't need FASTQ splitting.
- **The `--save_demux_fastqs` flag** controls whether step 4's outputs are published. The splitting still runs regardless (for potential downstream use), but files are only copied to the output directory when this flag is `true`.
