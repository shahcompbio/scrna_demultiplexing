import errno
import json
import os
import shutil
from glob import glob
from subprocess import Popen, PIPE

import pandas as pd
import pysam
import yaml


def makedirs(directory, isfile=False):
    if isfile:
        directory = os.path.dirname(directory)
        if not directory:
            return

    try:
        os.makedirs(directory)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise


def run_cmd(cmd, output=None):
    cmd = [str(v) for v in cmd]

    print(' '.join(cmd))

    stdout = PIPE
    if output:
        stdout = open(output, "w")

    p = Popen(cmd, stdout=stdout, stderr=PIPE)

    cmdout, cmderr = p.communicate()
    retc = p.returncode

    if retc:
        raise Exception(
            "command failed. stderr:{}, stdout:{}".format(
                cmdout,
                cmderr))

    if output:
        stdout.close()


def create_cmo(metadata, cmo_path):
    data = []

    for cmo in metadata['meta']['hashtag']:
        print(cmo)
        data.append({
            'id': cmo,
            'name': cmo,
            'read': 'R2',
            'pattern': '^NNNNNNNNNN(BC)NNNNNNNNN',
            'sequence': metadata['meta']['hashtag'][cmo]['sequence'],
            'feature_type': 'Multiplexing Capture',
        })

    pd.DataFrame(data).to_csv(cmo_path, index=False)


def create_antibodies(metadata, antibodies_path):
    data = []
    for cmo in metadata['meta']['citeseq']:
        data.append({
            'id': cmo,
            'name': metadata['meta']['citeseq'][cmo]['protein'].split(' ')[1].replace(',', '').strip(),
            'read': 'R2',
            'pattern': '^NNNNNNNNNN(BC)NNNNNNNNN',
            'sequence': metadata['meta']['citeseq'][cmo]['sequence'],
            'feature_type': 'Antibody Capture',
        })

    pd.DataFrame(data).to_csv(antibodies_path, index=False)


def create_initial_run_multiconfig(
        metadata,
        reference,
        cmo_path,
        antibodies_path,
        multiconfig_path,
        fastq_data
):
    lines = [
        f'[gene-expression]',
        f'reference,{reference}',
        f'cmo-set,{cmo_path}',
        f'[feature]',
        f'reference,{antibodies_path}',
        f'[libraries]',
        f'fastq_id,fastqs,feature_types',
    ]

    for fastq_info in fastq_data:
        lines.append(f"{fastq_info['id']},{fastq_info['fastq']},{fastq_info['type']}")

    lines.append('[samples]'),
    lines.append('sample_id,cmo_ids')
    for hashtag in metadata['meta']['hashtag'].keys():
        lines.append(f"{metadata['meta']['hashtag'][hashtag]['sample_id']},{hashtag}")

    with open(multiconfig_path, 'w') as f:
        f.writelines('\n'.join(lines))


def cellranger_multi(
        reference,
        meta_yaml,
        gex_fastq,
        gex_identifier,
        cite_fastq,
        cite_identifier,
        outdir,
        tempdir,
        numcores=16,
        mempercore=10,
        maxjobs=200,
        jobmode='local'
):
    os.makedirs(tempdir)
    os.makedirs(os.path.join(tempdir, 'configs'))

    cmo_path = os.path.join(tempdir, 'configs', 'cmo.txt')
    antibodies_path = os.path.join(tempdir, 'configs', 'antibodies.txt')
    multiconfig_path = os.path.join(tempdir, 'configs', 'multiconfig.txt')

    metadata = yaml.safe_load(open(meta_yaml, 'rt'))

    create_cmo(metadata, cmo_path)
    create_antibodies(metadata, antibodies_path)

    reference = os.path.abspath(reference)
    cmo_path = os.path.abspath(cmo_path)
    antibodies_path = os.path.abspath(antibodies_path)
    gex_fastq = os.path.abspath(gex_fastq)
    cite_fastq = os.path.abspath(cite_fastq)

    create_initial_run_multiconfig(
        metadata, reference, cmo_path, antibodies_path, multiconfig_path,
        [
            {'type': 'Gene Expression', 'id': gex_identifier, 'fastq': gex_fastq},
            {'type': 'Multiplexing Capture', 'id': cite_identifier, 'fastq': cite_fastq}
        ]
    )

    cmd = [
        'cellranger',
        'multi',
        '--csv=' + multiconfig_path,
        '--id=' + outdir,
        f'--localcores={numcores}',
        f'--localmem={mempercore}',
        f'--maxjobs={maxjobs}',
        f'--mempercore={mempercore}',
        f'--jobmode={jobmode}',
        '--disable-ui'
    ]

    run_cmd(cmd)

    bam_dirs = glob(f'{outdir}/outs/per_sample_outs/*')

    for bam_dir in bam_dirs:
        sampleid = os.path.basename(bam_dir)
        metrics = os.path.join(bam_dir, 'metrics_summary.csv')

        df = pd.read_csv(metrics)

        df = df.append({
            'Category': 'Library',
            'Metric Name': 'Sample Id',
            'Metric Value': sampleid
        },
        ignore_index=True)

        df.to_csv(os.path.join(bam_dir, 'metrics_summary_annotated.csv'), index=False)



def create_vdj_run_multiconfig(
        reference,
        feature_reference,
        vdj_reference,
        multiconfig_path,
        fastq_data,
        gex_metrics
):
    numreads, numcells, sample_id = read_metrics(gex_metrics)

    lines = [
        f'[gene-expression]',
        f'reference,{reference}',
        f'force-cells,{numcells}',
        f'check-library-compatibility,false',
        f'[feature]',
        f'reference,{feature_reference}',
        f'[vdj]',
        f'reference,{vdj_reference}',
        f'[libraries]',
        f'fastq_id,fastqs,feature_types',
    ]

    for fastq_info in fastq_data:
        lines.append(f"{fastq_info['id']},{fastq_info['fastq']},{fastq_info['type']}")

    with open(multiconfig_path, 'w') as f:
        f.writelines('\n'.join(lines))


def cellranger_multi_vdj(
        reference,
        feature_reference,
        vdj_reference,
        gex_fastq,
        gex_identifier,
        gex_metrics,
        tcr_fastq,
        tcr_identifier,
        cite_fastq,
        cite_identifier,
        outdir,
        tempdir,
        numcores=16,
        mempercore=10,
        maxjobs=200,
        jobmode='local'
):
    os.makedirs(tempdir)
    os.makedirs(os.path.join(tempdir, 'configs'))


    numreads, numcells, sample_id = read_metrics(gex_metrics)

    multiconfig_path = os.path.join(tempdir, 'configs', 'multiconfig.txt')

    reference = os.path.abspath(reference)
    feature_reference = os.path.abspath(feature_reference)
    vdj_reference = os.path.abspath(vdj_reference)

    gex_fastq = os.path.abspath(gex_fastq)
    tcr_fastq = os.path.abspath(tcr_fastq)

    create_vdj_run_multiconfig(
        reference, feature_reference, vdj_reference, multiconfig_path,
        [
            {'type': 'Gene Expression', 'id': gex_identifier, 'fastq': gex_fastq},
            {'type': 'Antibody Capture', 'id': cite_identifier, 'fastq': cite_fastq}
            {'type': 'VDJ-T', 'id': tcr_identifier, 'fastq': tcr_fastq}
        ],
        gex_metrics
    )

    cmd = [
        'cellranger',
        'multi',
        '--csv=' + multiconfig_path,
        '--id=' + sample_id,
        f'--localcores={numcores}',
        f'--localmem={mempercore}',
        f'--mempercore={mempercore}',
        f'--maxjobs={maxjobs}',
        f'--jobmode={jobmode}',
        '--disable-ui'
    ]

    run_cmd(cmd)

    os.makedirs(outdir)

    os.rename(sample_id, f'{outdir}/{sample_id}')



def read_metrics(metrics):
    df = pd.read_csv(metrics)

    numcells = df[df['Category'] == 'Cells']
    numcells = numcells[numcells['Library Type'] == 'Gene Expression']
    numcells = numcells[numcells['Metric Name'] == 'Cells']
    numcells = str(numcells['Metric Value'].iloc[0])
    numcells = int(numcells.replace(',','').strip())

    numreads = df[df['Category'] == 'Library']
    numreads = numreads[numreads['Library Type'] == 'Gene Expression']
    numreads = numreads[numreads['Grouped By'] == 'Physical library ID']
    numreads = numreads[numreads['Group Name'] == 'GEX_1']
    numreads = numreads[numreads['Metric Name'] == 'Number of reads']
    numreads = str(numreads['Metric Value'].iloc[0])
    numreads = int(numreads.replace(',', '').strip())

    sample_id = df[df['Category'] == 'Library']
    sample_id = sample_id[sample_id['Metric Name'] == 'Sample Id']
    sample_id = str(sample_id['Metric Value'].iloc[0])

    return numreads, numcells, sample_id


def find_gex_id(bam_file):
    with pysam.AlignmentFile(bam_file, 'rb') as reader:
        header = reader.header

    for comment in header['CO']:
        if not comment.startswith('library_info'):
            continue

        comment = comment[len('library_info:'):]
        comment = json.loads(comment)

        print(comment)

        if comment['library_type'] == 'Gene Expression':
            return comment['library_id'], comment['gem_group']

    raise Exception()


def find_fastqs_to_use(tempdir, library_id, gem_group):
    files = glob(f'{tempdir}/*_{library_id}_{gem_group}*/*')

    assert len(set([os.path.basename(v) for v in files])) == len(files)

    return files


def bam_to_fastq(bam_file, metrics, outdir, tempdir):
    os.makedirs(outdir)

    num_reads, num_cells, sample_id = read_metrics(metrics)

    library_id, gem_group = find_gex_id(bam_file)

    cmd = ['bamtofastq', f'--reads-per-fastq={num_reads+1000000}', bam_file, tempdir]

    run_cmd(cmd)


    fastqs = find_fastqs_to_use(tempdir, library_id, gem_group)



    for fastq in fastqs:
        shutil.copyfile(fastq, os.path.join(outdir, os.path.basename(fastq)))
