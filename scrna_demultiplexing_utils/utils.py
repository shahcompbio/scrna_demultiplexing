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


def get_feature_type_map():
    return {
        'gene_expression': 'Gene Expression',
        'hto': 'Multiplexing Capture',
        'cite': 'Multiplexing Capture',
        'tcr': 'VDJ-T',
    }


def create_cmo(metadata, cmo_path):
    data = []
    for cmo in metadata['meta']['hashtag']:
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
        metadata_path,
        reference,
        cmo_path,
        antibodies_path,
        multiconfig_path
):
    feature_type_map = get_feature_type_map()

    metadata = yaml.load(open(metadata_path))

    libraries = {}
    for file in metadata['files']:
        fastq_path = os.path.join(os.path.dirname(metadata_path), os.path.dirname(file))
        fastq_id = metadata['files'][file]['identifier']
        feature_type = feature_type_map[metadata['files'][file]['type']]

        if fastq_id not in libraries.keys():
            libraries[fastq_id] = {
                'fastq_path': fastq_path,
                'feature_type': feature_type,
            }

    lines = [
        f'[gene-expression]',
        f'reference,{reference}',
        f'cmo-set,{cmo_path}',
        f'[feature]',
        f'reference,{antibodies_path}',
        f'[libraries]',
        f'fastq_id,fastqs,feature_types',
    ]

    for fastq_id in libraries:
        if libraries[fastq_id]['feature_type'] != 'VDJ-T':
            lines.append(f"{fastq_id},{libraries[fastq_id]['fastq_path']},{libraries[fastq_id]['feature_type']}")

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
        cite_fastq,
        tempdir
):
    os.makedirs(tempdir)

    cmo_path = os.path.join(tempdir, 'cmo.txt')
    antibodies_path = os.path.join(tempdir, 'antibodies.txt')
    multiconfig_path = os.path.join(tempdir, 'multiconfig.txt')

    create_cmo(meta_yaml, cmo_path)
    create_antibodies(meta_yaml, antibodies_path)

    create_initial_run_multiconfig(meta_yaml, reference, cmo_path, antibodies_path, multiconfig_path)

    ...

    # cmd = [
    #     'cellranger', 'multi', '--csv=' + csv_file, '--id=' + tempdir,
    #     '--localcores='+cores, '--localmem='+memory
    # ]
    #
    # run_cmd(cmd)
