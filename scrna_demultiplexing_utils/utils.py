import errno
import os
from subprocess import Popen, PIPE

import pandas as pd
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
        memory=10,
        cores=16
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
        '--localcores=' + str(cores),
        '--localmem=' + str(memory)
    ]

    run_cmd(cmd)
