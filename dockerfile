FROM nfcore/cellranger:7.1.0

RUN conda install -c bioconda pysam
RUN pip install click pandas pyyaml
RUN wget https://github.com/10XGenomics/bamtofastq/releases/download/v1.4.1/bamtofastq_linux && chmod 777 bamtofastq_linux && mv bamtofastq_linux /usr/bin/bamtofastq