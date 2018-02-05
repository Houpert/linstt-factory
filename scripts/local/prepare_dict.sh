#!/bin/bash

# Copyright 2017 @Linagora Abdel HEBA OK

# Prepares the dictionary and auto-generates the pronunciations for the words,
# that are in our vocabulary but not in CMUdict
# Yup :)

stage=0
nj=4 # number of parallel Sequitur G2P jobs, we would like to use
cmd=run.pl


. utils/parse_options.sh || exit 1;
. path.sh || exit 1
export LC_ALL=C


# this file is either a copy of the lexicon we download from openslr.org/11 or is
# created by the G2P steps below, see Run_training Notebook
lexicon_raw_nosil=$1
dst_dir=$2



 silence_phones=$dst_dir/silence_phones.txt
 optional_silence=$dst_dir/optional_silence.txt
 nonsil_phones=$dst_dir/nonsilence_phones.txt
 extra_questions=$dst_dir/extra_questions.txt

 echo "Preparing phone lists and clustering questions"
 (echo SIL; echo SPN; echo NSN; echo LAU;) > $silence_phones
  #(echo SIL; echo SPN;) > $silence_phones
 echo SIL > $optional_silence
  # nonsilence phones; on each line is a list of phones that correspond
  # really to the same base phone.
 awk '{for (i=2; i<=NF; ++i) { print $i; gsub(/[0-9]/, "", $i); print $i}}' $lexicon_raw_nosil |\
   sort -u |\
   perl -e 'while(<>){
     chop; m:^([^\d]+)(\d*)$: || die "Bad phone $_";
     $phones_of{$1} .= "$_ "; }
     foreach $list (values %phones_of) {print $list . "\n"; } ' \
     > $nonsil_phones || exit 1;
  # A few extra questions that will be added to those obtained by automatically clustering
  # the "real" phones.  These ask about stress; there's also one for silence.
 cat $silence_phones| awk '{printf("%s ", $1);} END{printf "\n";}' > $extra_questions || exit 1;
 cat $nonsil_phones | perl -e 'while(<>){ foreach $p (split(" ", $_)) {
   $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' \
   >> $extra_questions || exit 1;
 echo "$(wc -l <$silence_phones) silence phones saved to: $silence_phones"
 echo "$(wc -l <$optional_silence) optional silence saved to: $optional_silence"
 echo "$(wc -l <$nonsil_phones) non-silence phones saved to: $nonsil_phones"
 echo "$(wc -l <$extra_questions) extra triphone clustering-related questions saved to: $extra_questions"


 # TCOF
 #(echo '!sil SIL'; echo '<spoken_noise> SPN'; echo '<UNK> SPN'; echo '<laugh> LAU'; echo '<noise> NSN') |\
 # ESTER
 (echo '<unk> SPN'; echo '<laugh> LAU'; echo '<noise> NSN'; echo '<top> NSN';\
  echo '<whisperedvoice> NSN'; echo '<breath> SPN'; echo '<blowshard> NSN'; echo '<cough> SPN'; echo '<glottisblow> SPN';\
  echo '<noisemouth> SPN';echo '<whistling> NSN') |\
 # ESTER without noise states
 #(echo '!sil SIL'; echo '<UNK> SPN') |\
 cat - $lexicon_raw_nosil | sort | uniq >$dst_dir/lexicon.txt
 echo "Lexicon text file saved as: $dst_dir/lexicon.txt"

exit 0
