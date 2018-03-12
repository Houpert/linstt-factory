#!/bin/bash
. path.sh
. cmd.sh

AM=$1
LM_arpa=$2
Lang_dir=$3
SYSTEM=$4

local/format_lms.sh --src-dir $Lang_dir $LM_arpa

utils/mkgraph.sh ${Lang_dir}_test_text \
		 $AM $SYSTEM/Graph

cp -r $AM/* $SYSTEM

echo "Successfuly Gen $SYSTEM"
