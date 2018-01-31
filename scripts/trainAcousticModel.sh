#!/bin/bash

. cmd.sh
. path.sh
exp_dir=$(readlink -f $1)
nj_training=$2
nj_decoding=$3

