FROM ubuntu:18.04

### basics
RUN apt-get update && apt-get install --yes \
    build-essential \
    gcc-multilib \
    gfortran \
    apt-utils \
    zlib1g-dev \
    liblzma-dev \
    xorg-dev \
    libreadline-dev \
    libpcre++-dev \
    libcurl4 \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    openjdk-8-jdk \
    vim-common \
    git \
    g++

# Upgrade installed packages
RUN apt upgrade -y && apt clean

# install python 3.7.10 (or newer)
RUN apt update && \
    apt install --no-install-recommends -y build-essential software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt install --no-install-recommends -y python3.7 python3.7-dev python3.7-distutils && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Register the version in alternatives (and set higher priority to 3.7)
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2

# Upgrade pip to latest version
RUN curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py --force-reinstall && \
    rm get-pip.py

WORKDIR /opt

RUN apt-get update && apt-get install --yes \
    libbz2-dev \
    wget && \
    export JAVA_HOME="/opt/java/jre/" && export PATH=$PATH:$JAVA_HOME/bin && \
    pip3 install snakemake==5.26.1 && pip3 install pandas && \
    wget https://cran.r-project.org/bin/linux/ubuntu/bionic-cran35/r-base_3.6.3.orig.tar.gz && \
    tar -xvzf /opt/r-base_3.6.3.orig.tar.gz && cd R-3.6.3/ &&  ./configure && make && cd /opt/ && \
    mkdir -p /mnt/DATA6/mouseData/ && mkdir -p /usr/bin/ && mkdir -p /mnt/tmp/ && \
    cp /opt/R-3.6.3/bin/R /usr/bin/ && cp /opt/R-3.6.3/bin/Rscript /usr/bin/ && \
    wget https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2 -O bcftools.tar.bz2 && \
    tar -xjvf bcftools.tar.bz2 && cd bcftools-1.3.1/ && make && make prefix=/usr/local/bin install && \
    ln -s /usr/local/bin/bin/bcftools /usr/bin/bcftools && \
    cd /opt && wget http://www.openbioinformatics.org/annovar/download/0wgxR2rIVP/annovar.latest.tar.gz && \
    tar -xvzf annovar.latest.tar.gz

# to create mousedbs for annovar & required R libraries
RUN perl /opt/annovar/annotate_variation.pl -downdb -buildver mm10 -webfrom annovar refGene mousedb/ && \
    perl /opt/annovar/annotate_variation.pl --buildver mm10 --downdb seq mousedb/mm10_seq && \
    perl /opt/annovar/retrieve_seq_from_fasta.pl mousedb/mm10_refGene.txt -seqdir mousedb/mm10_seq -format refGene -outfile mousedb/mm10_refGeneMrna.fa && \
    /usr/bin/R -e "install.packages(c('stringr', 'optparse', 'vcfR'), dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    cd /mnt/DATA6/mouseData/ && apt-get update && apt-get install --yes tabix

COPY forceCallsAnnoSnakefile 20210524processingVarAnno.R bbnCombinedAnno /mnt/DATA6/mouseData/
COPY mm10_mgp.v6.combinedMouseFilt.txt /opt/mousedb/

WORKDIR /mnt/DATA6/mouseData/

# when I add genotype steps make sure I have snakemake.ignore so combined vcf isn't processed
# loop may ensue i.e thinks there is new vcf from combined -> new combined

CMD snakemake --snakefile forceCallsAnnoSnakefile -k --jobs 10 || true && \
    snakemake --snakefile bbnCombinedAnno -k --jobs 5
