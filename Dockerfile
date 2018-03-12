FROM nvidia/cuda:7.5
MAINTAINER Abdel HEBA <aheba@linagora.com>

# Install all our dependencies and set some required build changes
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bzip2 \
    openjdk-6-jre \
    g++ \
    gawk \
    git \
    gzip \
    libatlas3-base \
    libtool \
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

ENV BASE_DIR /opt/lvcsrPlatform
#ENV LANG C.UTF-8

RUN mkdir -p $BASE_DIR/database \
    	     $BASE_DIR/decoding \
	     $BASE_DIR/systems \
	     $BASE_DIR/tmp \
	     $BASE_DIR/tools \
	     $BASE_DIR/training/AM \
	     $BASE_DIR/training/LM \
	     $BASE_DIR/training/LEX

# Speaker diarization
RUN cd $BASE_DIR/tools && wget http://www-lium.univ-lemans.fr/diarization/lib/exe/fetch.php/lium_spkdiarization-8.4.1.jar.gz && \
    gzip -d lium_spkdiarization-8.4.1.jar.gz

# Build kaldi
RUN cd $BASE_DIR/tools && git clone https://github.com/kaldi-asr/kaldi.git --origin upstream
RUN cd $BASE_DIR/tools/kaldi/tools && \
    make -j 12 && extras/install_irstlm.sh && extras/install_sequitur.sh && extras/install_speex.sh &&\
    cd $BASE_DIR/tools/kaldi/src && ./configure --shared && make depend -j 12 && make -j 12
	     
WORKDIR $BASE_DIR
RUN pip3 install --upgrade pip
COPY requirements.txt .
RUN pip3 install -r requirements.txt
RUN python3 -m bash_kernel.install
RUN python3 -m pip install ipykernel
RUN python3 -m ipykernel install --user
COPY requirements_pip3.txt .
RUN pip3 install -r requirements_pip3.txt
RUN ln -s /opt/kaldi /opt/lvcsrPlatform/tools/kaldi


COPY tools/srilm.tgz tools/srilm.tgz
RUN cp $BASE_DIR/tools/srilm.tgz $BASE_DIR/tools/kaldi/tools && cd $BASE_DIR/tools/kaldi/tools && extras/install_srilm.sh
RUN apt-get install -y libboost-all-dev && cd $BASE_DIR/tools && git clone https://github.com/vchahun/kenlm.git && cd kenlm && ./bjam

# Copy Scripts
COPY scripts scripts

# Copy g2p model
COPY tools/g2p tools/g2p
# Copy CMU lexicon for french vocabulary
COPY training/LEX training/LEX
COPY tmp tmp

RUN locale-gen fr_FR.UTF-8
#ENV LANG fr_FR.UTF-8
#ENV LANGUAGE fr_FR:fr
#ENV LC_ALL fr_FR.UTF-8

ENV LANG=fr_Fr.UTF-8
ENV LANGUAGE=fr_FR.UTF-8
ENV LC_ALL=fr_FR.UTF-8

EXPOSE 8888

CMD source ~/.bashrc && jupyter-notebook --port=8888 --ip=172.17.0.2 --allow-root
