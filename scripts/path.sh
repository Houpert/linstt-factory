#!/usr/bin/env bash
ASR_platform_dir=/opt/ASR_platform
export KALDI_ROOT=$ASR_platform_dir/tools/kaldi

export PATH=$KALDI_ROOT/src/bin:\
$KALDI_ROOT/src/chainbin:\
$KALDI_ROOT/src/featbin:\
$KALDI_ROOT/src/fgmmbin:\
$KALDI_ROOT/tools/fstbin:\
$KALDI_ROOT/src/gmmbin:\
$KALDI_ROOT/src/ivectorbin:\
$KALDI_ROOT/src/kwsbin:\
$KALDI_ROOT/src/latbin:\
$KALDI_ROOT/src/lmbin:\
$KALDI_ROOT/src/nnet2bin:\
$KALDI_ROOT/src/nnet3bin:\
$KALDI_ROOT/src/nnetbin:\
$KALDI_ROOT/src/online2bin:\
$KALDI_ROOT/src/onlinebin:\
$KALDI_ROOT/src/sgmm2bin:\
$KALDI_ROOT/src/sgmmbin:\
$KALDI_ROOT/tools/openfst/bin:
$KALDI_ROOT/tools/irstlm/bin:\
$ASR_platform_dir/scripts/utils:\
/usr/local/cuda-7.5/bin:$PATH
PYTHON='python2.7'
PYTHON3='python3'

# Sequitur G2P executable
sequitur=$KALDI_ROOT/tools/sequitur/g2p.py
sequitur_path="$(dirname $sequitur)/lib/$PYTHON/site-packages"

export LD_LIBRARY_PATH=/usr/local/cuda-7.5/lib64:$LD_LIBRARY_PATH

export LANG=fr_Fr.UTF-8
export LANGUAGE=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

