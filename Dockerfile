FROM nvidia/cuda:7.5
MAINTAINER Abdel HEBA <aheba@linagora.com>

# Install all dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bzip2 \
    g++ \
    gawk \
    git \
    gzip \
    libatlas3-base \
    libtool \
    locales \
    make \
    python2.7 \
    python-dev \
    python-numpy \
    python-pip \
    python3   \
    python3-pip \
    swig \
    sox \
    subversion \
    wget \
    zlib1g-dev &&\
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    ln -s /usr/bin/python2.7 /usr/bin/python ; ln -s -f bash /bin/sh

# Workspace directory
ENV BASE_DIR /opt/ASR_platform
WORKDIR $BASE_DIR
RUN mkdir -p $BASE_DIR/corpus \
    	     $BASE_DIR/scripts \
	     $BASE_DIR/data/text \
	     $BASE_DIR/tools/kaldi \
	     $BASE_DIR/ASR_exp/exp_am \
	     $BASE_DIR/ASR_exp/exp_lm \
	     $BASE_DIR/ASR_exp/dict \
	     $BASE_DIR/ASR_exp/ASR_sys

# Build kaldi
# We use number of proc specified in Proc.txt
RUN git clone https://github.com/kaldi-asr/kaldi.git --origin upstream $BASE_DIR/tools/kaldi
RUN cd $BASE_DIR/tools/kaldi/tools && \
    make -j 4 && extras/install_irstlm.sh && extras/install_sequitur.sh && extras/install_speex.sh &&\
    cd $BASE_DIR/tools/kaldi/src && ./configure --shared && make depend -j 4 && make -j 4

# Install Jupyter-notebook with Bash - Python2 -Python3 kernels
RUN pip3 install --upgrade pip
COPY requirements.txt .
RUN pip3 install -r requirements.txt
RUN python3 -m bash_kernel.install
RUN python3 -m pip install ipykernel
RUN python3 -m ipykernel install --user
COPY requirements_pip3.txt .
RUN pip3 install -r requirements_pip3.txt

# Copy our receipe - scripts - g2p model - CMU lexicon for french vocabulary
COPY scripts scripts
COPY tools/ tools/
COPY ASR_exp/dict/dict_fr ASR_exp/dict/dict_fr

# Configure fr_FR.UTF-8 to use for french accent
RUN locale-gen fr_FR.UTF-8
ENV LANG=fr_Fr.UTF-8
ENV LANGUAGE=fr_FR.UTF-8
ENV LC_ALL=fr_FR.UTF-8

EXPOSE 8888

CMD source ~/.bashrc && jupyter-notebook --port=8888 --ip=172.17.0.2 --allow-root