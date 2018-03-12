#!/bin/bash

. cmd.sh
. path.sh


exp_dir=$1
idata_kaldi=$exp_dir/data
lexicon=$2
nj_training=$3
mfccdir=$idata_kaldi/mfcc

# Params Training
# Monophone
exp_mono=$exp_dir/mono
boost_silence=1.25
# Triphone 1
tri1_step1=$exp_mono/tri1_2K_100K
num_leaves_step1=2500
tot_gauss_step1=100000
# Triphone 2
tri1_step2=$tri1_step1/tri1_4K_15K
num_leaves_step2=4000
tot_gauss_step2=150000
# Triphone + LDA + MLLT
tri2_step1=$tri1_step2/tri2_5K_200K
context_dependence="--left-context=3 --right-context=3"
num_leaves_step3=5000
tot_gauss_step3=200000
# Triphone SAT 1
tri3_ali=$tri2_step1/tri3_align_fmllr
tri3_step1=$tri2_step1/tri3_SAT_7K_250K
num_leaves_step3=7000
tot_gauss_step3=250000
# Triphone SAT 2
tri3_step2=$tri3_step1/tri3_SAT_8K_300K
num_leaves_step4=8000
tot_gauss_step4=300000
#MFCC features
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj_training $idata_kaldi/map_files $exp_kaldi/make_mfcc/map_files $mfccdir
steps/compute_cmvn_stats.sh $idata_kaldi/map_files $exp_kaldi/make_mfcc/$part $mfccdir
utils/fix_data_dir.sh $idata_kaldi/map_files


cat $lexicon | awk '{$1="";print $0}' | tr ' ' '\n' | sort -b | uniq -c
mkdir -p $idata_kaldi/local/dict/cmudict
cp $lexicon $idata_kaldi/local/dict/fr.dict

dict_output=$idata_kaldi/local/dict
local/prepare_dict.sh $lexicon $dict_output

#### Prepare Lang ==> L.fst Vocabulary's automate finite state
utils/prepare_lang.sh $idata_kaldi/local/dict \
   "<unk>" $idata_kaldi/local/lang_tmp $idata_kaldi/lang
   


# Monophone
steps/train_mono.sh --boost-silence $boost_silence --nj $nj_training --cmd "$train_cmd" \
   $idata_kaldi/map_files $idata_kaldi/lang $exp_mono

steps/train_deltas.sh --boost-silence $boost_silence --cmd "$train_cmd" \
     $num_leaves_step1 $tot_gauss_step1 $idata_kaldi/map_files $idata_kaldi/lang $exp_mono \
     $tri1_step1

# seconde step triphone
steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
     $num_leaves_step2 $tot_gauss_step2 $idata_kaldi/map_files $idata_kaldi/lang $tri1_step1 \
     $tri1_step2

# Train lda_mllt based-on best models
steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "$context_dependence" $num_leaves_step3 $tot_gauss_step3 \
    $idata_kaldi/map_files \
    $idata_kaldi/lang \
    $tri1_step2 \
    $tri2_step1

steps/align_fmllr.sh --nj $nj_training --cmd "$train_cmd" \
   $idata_kaldi/map_files $idata_kaldi/lang $tri2_step1 $tri3_ali

steps/train_sat.sh  --cmd "$train_cmd" $num_leaves_step3 $tot_gauss_step3\
   $idata_kaldi/map_files $idata_kaldi/lang $tri3_ali $tri3_step1

steps/train_sat.sh  --cmd "$train_cmd" $num_leaves_step4 $tot_gauss_step4 \
 $idata_kaldi/map_files $idata_kaldi/lang $tri3_step1 \


 ######## Neural Networks using CUDA & GPU
 # if you don't have a GPU you won't be able to go further.
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs,
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR:
#    the objective is to emphasize state-sequences with better
#    frame accuracy w.r.t. reference alignment.

# Config:
# gmmdir=$tri3_step
# data_fmllr=$tri3_step/data-fmllr-tri3
# if [ $stage -le 5 ]; then
# 	# Store fMLLR features, so we can train on them easily,
# 	dir=$data_fmllr/train
# 	steps/nnet/make_fmllr_feats.sh --nj $nj_training --cmd "$train_cmd" --transform-dir ${gmmdir}_ali $dir $traindir $gmmdir $dir/log $dir/data || exit 1
# 	# split the data : 90% train 10% cross-validation (held-out)
# 	utils/subset_data_dir_tr_cv.sh $dir ${dir}_tr90 ${dir}_cv10 || exit 1
# fi

# if [ $stage -le 6 ]; then
# 	# Pre-train DBN, i.e. a stack of RBMs
# 	dir=$expedir/dnn4_pretrain-dbn
# 	(tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)& # forward log
# 	$cuda_cmd $dir/log/pretrain_dbn.log \
# 	steps/nnet/pretrain_dbn.sh --rbm-iter 1 $data_fmllr/train $dir || exit 1;
# fi

# if [ $stage -le 7 ]; then
# 	# Train the DNN optimizing per-frame cross-entropy.
# 	dir=$expedir/dnn4_pretrain-dbn_dnn
# 	ali=${gmmdir}_ali
# 	feature_transform=$expedir/dnn4_pretrain-dbn/final.feature_transform
# 	dbn=$expedir/dnn4_pretrain-dbn/6.dbn
# 	(tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
# 	# Train
# 	$cuda_cmd $dir/log/train_nnet.log \
# 	steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
# 	$data_fmllr/train_tr90 $data_fmllr/train_cv10 $langdir $ali $ali $dir || exit 1;
# fi

# # Sequence training using sMBR criterion, we do Stochastic-GD
# # with per-utterance updates. We use usually good acwt 0.1
# # Lattices are re-generated after 1st epoch, to get faster convergence.
# dir=$expedir/dnn4_pretrain-dbn_dnn_smbr
# srcdir=$expedir/dnn4_pretrain-dbn_dnn
# acwt=0.1

# if [ $stage -le 8 ]; then
# 	[ ! -d $lvcsrRootDir/scripts/conf ] && mkdir $lvcsrRootDir/scripts/conf
# 	echo "beam=13.0
# lattice_beam=8.0" > $lvcsrRootDir/scripts/conf/decode_dnn.conf

# 	# First we generate lattices and alignments:
# 	steps/nnet/align.sh --nj 4 --cmd "$train_cmd" --use_gpu "yes" \
# 	$data_fmllr/train $langdir $srcdir ${srcdir}_ali || exit 1;

# 	steps/nnet/make_denlats.sh --nj 1 --use_gpu "yes" --sub-split $nj --cmd "$decode_cmd" --config $lvcsrRootDir/scripts/conf/decode_dnn.conf \
# 	--acwt $acwt $data_fmllr/train $langdir $srcdir ${srcdir}_denlats || exit 1;
# fi

# if [ $stage -le 9 ]; then
# 	# Re-train the DNN by 1 iteration of sMBR
# 	steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 1 --acwt $acwt --do-smbr true \
# 	$data_fmllr/train $langdir $srcdir ${srcdir}_ali ${srcdir}_denlats $dir || exit 1
# fi

# # Re-generate lattices, run 4 more sMBR iterations
# dir=$expedir/dnn4_pretrain-dbn_dnn_smbr_i1lats
# srcdir=$expedir/dnn4_pretrain-dbn_dnn_smbr
# acwt=0.1

# if [ $stage -le 10 ]; then
# 	# First we generate lattices and alignments:
# 	steps/nnet/align.sh --nj 4 --cmd "$train_cmd" --use_gpu "yes" \
# 	$data_fmllr/train $langdir $srcdir ${srcdir}_ali || exit 1;
# 	steps/nnet/make_denlats.sh --nj 1 --use_gpu "yes" --sub-split $nj --cmd "$decode_cmd" --config $lvcsrRootDir/scripts/conf/decode_dnn.conf \
# 	--acwt $acwt $data_fmllr/train $langdir $srcdir ${srcdir}_denlats || exit 1;
# fi

# if [ $stage -le 11 ]; then
# 	# Re-train the DNN by 1 iteration of sMBR
# 	steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 4 --acwt $acwt --do-smbr true \
# 	$data_fmllr/train $langdir $srcdir ${srcdir}_ali ${srcdir}_denlats $dir || exit 1
# fi

# if [ $stage -le 12 ]; then
#  	steps/decode_fmllr.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
# $expedir/tri3/graph $expedir/data/dev/ $expedir/tri3/decode_dev

# fi

# echo success...
# exit 0
