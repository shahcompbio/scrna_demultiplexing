import errno
import os
from subprocess import Popen, PIPE


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


def generate_config(cmo_csv, gex_fastq, multiplex_capture_fastq, reference, config_file):

    with open(config_file, 'wt') as writer:

        writer.write('[gene-expression]\n')
        writer.write(f'reference,{reference}\n')
        writer.write(f'cmo-set,{cmo_csv}\n')



def cellranger_multi(
        reference,
        cmo_csv,
        gex_fastq,
        multiplex_capture_fastq,
        tempdir
):
    cmd = [
        'cellranger', 'multi', '--csv=' + csv_file, '--id=' + tempdir,
        '--localcores='+cores, '--localmem='+memory
    ]

    run_cmd(cmd)
