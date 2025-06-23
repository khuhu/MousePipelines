FROM ubuntu:18.04

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
    python3-pip \
    libbz2-dev \
    wget && \
    export JAVA_HOME="/opt/java/jre/" && export PATH=$PATH:$JAVA_HOME/bin && \
    pip3 install snakemake && pip3 install pandas && \
    wget https://cran.r-project.org/bin/linux/ubuntu/bionic-cran35/r-base_3.6.3.orig.tar.gz && \
    tar -xvzf /opt/r-base_3.6.3.orig.tar.gz && cd R-3.6.3/ &&  ./configure && make && \
    mkdir -p /mnt/DATA6/mouseData/ && mkdir -p /usr/bin/ && \
    cp /opt/R-3.6.3/bin/R /usr/bin/ && cp /opt/R-3.6.3/bin/Rscript /usr/bin/

RUN /usr/bin/R -e "install.packages(c('BiocManager', 'stringr', 'optparse', 'foreach', 'doParallel', 'jsonlite'), dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    /usr/bin/R -e "BiocManager::install(c('DNAcopy','GenomicRanges'))"    

COPY 20200908mouseCnaScript.R 20210517segmentationScript.R 20210521snakeFileInputs.R cnSnakefileV2 /mnt/DATA6/mouseData/

WORKDIR /mnt/DATA6/mouseData/

CMD /usr/bin/Rscript --vanilla 20210521snakeFileInputs.R && \
    snakemake --snakefile cnSnakefileV2 -k --jobs 3 
