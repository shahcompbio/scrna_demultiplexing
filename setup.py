import versioneer
from setuptools import setup, find_packages

setup(
    name='scrna_demultiplexing_utils',
    packages=find_packages(),
    version=versioneer.get_version(),
    cmdclass=versioneer.get_cmdclass(),
    description='python utilities for vdj',
    author='Shah lab',
    author_email='',
    entry_points={
        'console_scripts': [
            'scrna_demultiplexing_utils = scrna_demultiplexing_utils.cli:cli',
        ]
    },
    package_data={'': ['*.py', '*.R', '*.npz', "*.yaml", "data/*", "*.sh"]}
)
