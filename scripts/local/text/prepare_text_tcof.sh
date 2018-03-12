#!/bin/bash

# Copyright 2017 Abdel HEBA, @Linagora | DONE

# This is the top-level LM training script

. path.sh || exit 1
. cmd.sh || exit 1

# use to skip some of the initial steps
stage=1

# how many words we want in the LM's vocabulary
vocab_size=400000

# LM pruning threshold for the 'small' trigram model
prune_thresh_small=0.0000003

# LM pruning threshold for the 'medium' trigram model
prune_thresh_medium=0.0000001


. utils/parse_options.sh || exit 1

if [[ $# -ne 4 ]]; then
    echo "Usage: $1 <lm-texts-root> <tmp-dir> <txt-norm-root> <out-lm-dir>"
    echo "where,"
    echo "  <lm-text-root>: the root directory containing the raw(unnormalized) LM training texts"
    echo "  <tmp-dir>: store the temp files into this dir"
    echo "  <txt-norm-root>: store the normalized texts in subdirectories under this root dir"
    echo "  <out-lm-dir>: the directory to store the trained ARPA model"
    exit 1
fi

corpus_dir=$1
tmp_dir=$2
norm_dir=$3
lm_dir=$4

[[ -d "$corpus_dir" ]] || { echo "No such directory '$corpus_dir'"; exit 1; }
# Normalize data
normjobs=4
split_prefix=$tmp_dir/split

if [ "$stage" -le 1 ]; then
    mkdir -p $tmp_dir
    echo "Splitting into $normjobs parts, to allow for parallel processing ..."
    split_files=$(eval "echo $split_prefix-{$(seq -s',' $normjobs)}")
    # Tcof
    #find $corpus_dir -mindepth 1 -maxdepth 1 -type d |\
    find $corpus_dir -type f -name "*.trs" | sort |\
	tee $tmp_dir/all_texts.txt |\
	utils/split_scp.pl - $split_files
    echo "Checking the splits ..."
    total_count=$(wc -l <$tmp_dir/all_texts.txt)
    split_count=$(cat $split_files | wc -l | awk 'BEGIN{c=0} {c+=$1;} END{print c}')
    [[ "$total_count" -eq "$split_count" ]] || { echo "Inconsistent counts"; exit 1; }
fi

if [ "$stage" -le 2 ]; then
    echo "Performing text normalization ($normjobs jobs) - check $tmp_dir/txt_norm.JOB.log ..."
    mkdir -p $norm_dir
    $mkgraph_cmd JOB=1:$normjobs $tmp_dir/txt_norm.JOB.log \
		 local/text/normalize_text_tcof.sh $split_prefix-JOB $norm_dir || exit 1
    echo "Finished OK"
fi

word_counts=$lm_dir/word_counts.txt
vocab=$lm_dir/meeting-vocab.txt
full_corpus=$lm_dir/meeting-lm-norm.txt.gz

if [ "$stage" -le 3 ]; then
    echo "Selecting the vocabulary ($vocab_size words) ..."
    mkdir -p $lm_dir
    echo "Making the corpus and the vocabulary ..."
    # The following sequence of commands does the following:
    # 1) Eliminates duplicate sentences and saves the resulting corpus
    # 2) Splits the corpus into words
    # 3) Sorts the words in respect to their frequency
    # 4) Saves the list of the first $vocab_size words sorted by their frequencies
    # 5) Saves an alphabetically sorted vocabulary, that include the most frequent $vocab_size words
    for f in $(find $norm_dir -iname '*.txt'); do cat $f; done |\
	sort -u | tee >(gzip >$full_corpus) | tr -s '[[:space:]]' '\n' |\
	sort | uniq -c | sort -k1 -n -r |\
	head -n $vocab_size | tee $word_counts | awk '{print $2}' | sort >$vocab || exit 1
    echo "Word counts saved to '$word_counts'"
    echo "Vocabulary saved as '$vocab'"
    echo "All unique sentences (in sorted order) stored in '$full_corpus'"
    echo "Counting the total number word tokens in the corpus ..."
    echo "There are $(wc -w < <(zcat $full_corpus)) tokens in the corpus"
fi
