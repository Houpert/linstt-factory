#!/bin/bash

. path.sh

text_cleaned=$1
order=$2
dir_lm=$3
desc_lm=$4

mkdir -p $dir_lm

echo $desc_lm > $dir_lm/description.txt

cat $text_cleaned | add-start-end.sh > $dir_lm/text.sentence


### Build Language model with IRSTLm using the twol following commands
build-lm.sh -i $dir_lm/text.sentence -n $order -o $dir_lm/text.ilm.gz -k 5
