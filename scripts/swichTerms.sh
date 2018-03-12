#!/bin/bash

# $1: path lexicon which will be modified
# $2: mapwords
# $3: Lexicon

while read -r line
do
    word=`echo $line | awk '{print $1}'`
    map_words=`cat $2 | grep $word`
    if [[ ! -z "$map_words" ]]; then
	switch_word=`cat $2 | grep $word | awk '{print $1}'`
	echo $line | sed "s/$word/$switch_word/" >> $1/new_additionalTerms.dict
    else
	echo $line >> $1/new_additionalTerms.dict
    fi
done < $1/additionalTerms.dict

rm $1/additionalTerms.dict
mv $1/new_additionalTerms.dict $1/additionalTerms.dict
cat $1/additionalTerms.dict $3/lexicon.dict | sort -u > $1/lexicon.dict

echo "Swich Terms successfully complete.."
