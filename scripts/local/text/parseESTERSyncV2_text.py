#!/usr/bin/env python
# -*- coding: utf-8 -*-

from xml.etree import ElementTree as ET
from sys import argv
from num2words import num2words
from unidecode import unidecode
import re
import os.path

def transformation_text(text):
    # ESTER Problem "Mohamed v" ===> "Mohammed cinq"
    text=re.sub("mohammed vi","mohamed six",text)
    text=re.sub("mohammed v","mohamed cinq",text)
    # map all "mohamed" to "mohammed"
    text=re.sub("mohamed","mohammed",text)
    # character normalization:
    text=re.sub("&","et",text)
    text=re.sub("æ","ae",text)
    text=re.sub("œ","oe",text)
    # ESTER 2 Problem "19ème" ====> "dix-neuvième"
    text=re.sub("19ème","dix-neuvième",text)
    text=re.sub("Canal \+","canal plus",text)
    #if "###" in text or len(re.findall(r"\[.+\]", text)) > 0 or \
    #    len(re.findall(r"\p{L}+-[^\p{L}]|\p{L}+-$",text)) > 0 \
    #    or len(re.findall("[^\p{L}]-\p{L}+|^-\p{L}+", text)) > 0:
    #    bool=False
    #else:
    # ^^ remove
    text=re.sub(r"\^+","",text)
    text=re.sub(r"\_+","",text)
    # 4x4
    # Remove noise sound (BIP) over Name of places and person
    #text = re.sub(r"¤[^ ]+|[^ ]+¤|¤", "", text.strip())
    if len(re.findall(r"\dx\d",text))>0:
        text=re.sub(r"x","  ",text)
    if len(re.findall("\d+h\d+",text))>0:
        heures=re.findall("\d+h\d+",text)
        for h in heures:
            split_h=h.split('h')
            text_rep=split_h[0]+' heure '+split_h[1]
            text=text.replace(h, text_rep)
    text=re.sub(r',|¸',' ',text)
    # remove silence character : OK
    #text=re.sub(r"(/.+/","remplacer par la 1er",text)
    # Liaison non standard remarquable
    text=re.sub(r'=','',text)
    # Comment Transcriber
    text=re.sub(r'\{.+\}','',text)
    text=re.sub(r'\(.+\}','',text)
    #print "detecter (///|/|<|>)"
    # Remove undecidable variant heared like on (n') en:
    text=re.sub(r"\(.+\)|\(\)","",text)
    #text = re.sub(r"(\+|[*]+|///|/|<|>)", "", text.strip())
    #text=re.sub(r"-|_|\."," ",text.strip())
    text=re.sub(r'(O.K.)','ok',text)
    text = re.sub(r'(O.K)', 'ok', text)
    # Replace . with ''
    text=re.sub(r'\.|,|;','',text)
    #text=re.sub(r"{[^{]+}"," ",text.strip())
    # Remove ? ! < > : OK
    #<[^\p{L}]|[^\p{L}]>|#+|<\p{L}+[ ]|<\p{L}+$
    text=re.sub(r":|\?|/|\!|#+|²","",text)
    text=re.sub(r"%","pour cent",text)
    # replace silence character with <sil> : OK
    #text=re.sub(r"(\+)", "<sil>", text)
    #text=re.sub(r"(\+)", "!SIL", text)
    #text=re.sub(r"(///)", "!SIL", text)
    #text=re.sub(r"(///)", "<long-sil>", text)
    #if len(re.findall(r"/.+/", text)) > 0:
    #print "AVANT***********"+text
    #    for unchoosen_text in re.findall(r"/.+/", text):
    # choose first undecideble word
    #        unchoosen_word=unchoosen_text.split(',')
    #        for choosen_word in unchoosen_word:
    # isn't incomprehensible word
    #            if len(re.findall(r"\*+|\d+", choosen_word))==0:
    #                choosen_word = choosen_word.replace('/', '')
    #                text = text.replace(unchoosen_text, choosen_word)
    #print "Apres************"+text
    # Remove noise sound (BIP) over Name of places and person
    #text=re.sub(r"(¤.+¤)",'<NOISE>',text)
    # replace unkown syllable
    text=re.sub(r"\*+","",text)
    # cut of recording : OK
    #text=re.sub(r"\$+","",text)
    # remove " character: OK
    text = re.sub(r"\"+", "", text)
    # t 'avais
    text = re.sub(r"[ ]\'", "\'", text)
    text = re.sub(r"\'", "\' ", text)
    # for example : A43
    #num_list = re.findall("\w+?-?\d+", text)
    num_list = re.findall("[a-zA-Z]+\'*[a-zA-Z]*[-]?\d+""", text)
    if len(num_list) > 0:
        for s in num_list:
            split_between_char_int=re.findall(r'([a-zA-Z]+\'*[a-zA-Z]*)-?(\d+)',s)
            num_in_word = num2words(int(split_between_char_int[0][1]), lang='fr')
            #num_in_word=normalize('NFKD', num_in_word).encode('ascii', 'ignore')
            #text = re.sub(r"(^|[ ])"+str(s)+"([ ]|$)"," " + str(split_between_char_int[0][0]) +" "+ str(num_in_word) + " ",text)
            text = re.sub(r"(^|[ ])"+str(s)," " + str(split_between_char_int[0][0]) +" "+ str(num_in_word) + " ",text)
    #num_list = re.findall("\d+\w+", text)
    num_list = re.findall("\d+[a-zA-Z]+\'*[a-zA-Z]*", text)
    if len(num_list) > 0:
        for s in num_list:
            split_between_char_int=re.findall(r'(\d+)([a-zA-Z]+\'*[a-zA-Z]*)',s)
            #re.findall(r'\d+\w+',s)
            num_in_word = num2words(int(split_between_char_int[0][0]), lang='fr')
            #num_in_word=normalize('NFKD', num_in_word).encode('ascii', 'ignore')
            #text = re.sub(r"(^|[ ])"+str(s)+"([ ]|$)"," " + str(split_between_char_int[0][0]) +" "+ str(num_in_word) + " ",text)
            text = re.sub(r"(^|[ ])"+str(s)," "+ str(num_in_word)+ " " + str(split_between_char_int[0][1]) + " ",text)
    # convert number if exist : OK
    num_list = re.findall("\d+", text)
    if len(num_list) > 0:
        #print text
        #print "********************************* NUM2WORD"
        for num in num_list:
            num_in_word = num2words(int(num), lang='fr')
            #num_in_word=normalize('NFKD', num_in_word).encode('ascii', 'ignore')
            text = re.sub(r"(^|[ ])"+str(num)+"([ ]|$)"," " + str(num_in_word) + " ",text)
            #print text
        # replace n succesive spaces with one space. : OK
    text=re.sub(r"\s{2,}"," ",text)
    text=re.sub(r" $","",text)
    text=re.sub("^ ", '', text)
    # change bounding | to < and > : OK
    #balise=set(re.findall(r"\|\w+_?\w+\|",text))
    #if len(balise)>0:
    #print(balise)
    #    for b in balise:
    #        new_balise='<'+b[1:len(b)-1]+'>'
    #        text=text.replace(b,new_balise)
    #print(text)
    # c'est l'essaim ....
    text=text.lower()
    text=re.sub("[ ]-|-$","",text)
    return text
if __name__=="__main__":
    # Inputs
    file_trs=argv[1]
    #outdir=argv[2]
    basename=os.path.basename(file_trs.split('.')[0])
    # Read Trans File
    tree_trs = ET.parse(file_trs)
    trsdoc= tree_trs.getroot()
    #============================ Read MetaData =======================================
    #============================ Topic section (ID,DESC) =======================================
    for topic in trsdoc.iter('Topic'):
        topic_id=unidecode(topic.get('id'))
        topic_desc=unidecode(topic.get('desc'))
        #print(str(basename)+" "+topic_id+" "+topic_desc+"\n")
        #topic_file.write(str(basename)+" "+topic_id+" "+topic_desc+"\n")
    #============================ Speaker section (ID,GENDER) ===================================
    speaker_id=[]
    #namespk=[]
    speaker_gender=[]
    for spk in trsdoc.iter('Speaker'):
        id_spk=spk.get('id')
        #name_spk=unidecode(spk.get('name'))
        if spk.findall('type')==[]:
            gender="m"
        else:
            gender=unidecode(spk.get('type'))
            if gender =="female":
                gender="f"
            else:
                gender="m"
        #if isinstance(name_spk,str):
        #print(type(name_spk))
        #name_spk=normalize('NFKD', name_spk).encode('ascii', 'ignore')
        speaker_id.append(id_spk.replace(" ",""))
        speaker_gender.append([id_spk.replace(" ",""),gender.lower()])
        #namespk.append(name_spk.lower().replace(" ",""))
    #============================ Catch Transcription Segment and Topic Section ==================
    text=""
    Turn_count=0
    count=0
    has_attrib_speaker=False
    # set for uniq add
    Spk_that_contribute_to_meeting=set([])
    start_utt=0
    end_utt=0
    #Not used
    section_start_time=0
    section_end_time=0
    section_type=""
    section_topic=""
    nb_section=0
    spkr="spk1"
    for Element in trsdoc.iter():
        #OK validation
        #print("Print lekbirr "+str(Element.tail))
        #print("Print lekbirr "+str(Element.tail))
        if Element.tag=="Section":
            if nb_section>0:
                text = transformation_text(text)
                # File wav.scp
                # File utt2spk
                # File text
                # File speaker_gender
                if text!=""and has_attrib_speaker:
                    Spk_that_contribute_to_meeting.add(spkr)
                    #print("SAVED BY SECTION "+seg_id+" "+text)
                    seg_id = str(basename) + '_%s-%03d_Section%02d_Topic-%s_Turn-%03d_seg-%07d' % (
                    str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)),int(nb_section),str(section_topic), int(Turn_count), int(count))
                    spkr_id = str(basename)+'_%s-%03d' % (str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)))
                    #segments_file.write(seg_id+" "+basename+" "+str(start_utt)+" "+str(section_end_time)+"\n")
                    start_utt=section_end_time
                    #utt2spk_file.write(seg_id+" "+spkr_id+"\n")
                    #text_file.write(seg_id+" "+text+"\n")
                    print(text)
                    text=""
            # New section
            section_start_time=Element.get('startTime')
            section_end_time=Element.get('endTime')
            section_type=unidecode(Element.get('type'))
            #if Element.findall('topic')==[]:
            #    section_topic="None"
            #else:
            section_topic=unidecode(str(Element.get('topic')))
            if section_topic=="":
                section_topic="None"
            Turn_count=0
            count=0
            nb_section+=1
        elif Element.tag=="Turn":
            # if the turn is the spoken turn , not musical segment or noise
            #print(str(Element.tag))
            #print(Element.attrib)
            #print(Element.get("speaker"))
            if not "speaker" in Element.attrib:
                #print("pas de champ speaker")
                has_attrib_speaker=False
            else:
                if Element.get('speaker')=="":
                    #print("Cest vide: "+Element.get('speaker'))
                    has_attrib_speaker=False
                else:
                    #print(Element.get('speaker'))
                    # If the latest Utterance of previous Speaker is the latest one of his Turn speech
                    if Turn_count>0:
                        seg_id = str(basename) + '_%s-%03d_Section%02d_Topic-%s_Turn-%03d_seg-%07d' % (
                        str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)),int(nb_section),str(section_topic), int(Turn_count), int(count))
                        spkr_id = str(basename)+'_%s-%03d' % (str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)))
                        text = transformation_text(text)
                        # File wav.scp
                        # File utt2spk
                        # File text
                        # File speaker_gender
                        if bool and text!="":
                            #print("SAVED BY TURN "+seg_id+" "+text)
                            Spk_that_contribute_to_meeting.add(spkr)
                            #segments_file.write(seg_id+" "+basename+" "+str(start_utt)+" "+str(endTime)+"\n")
                            start_utt=endTime
                            #utt2spk_file.write(seg_id+" "+spkr_id+"\n")
                            #text_file.write(seg_id+" "+text+"\n")
                            print(text)
                            text=""
                        count = 0
                    # Get id_spkr
                    #print(Element.get('speaker'))
                    spkr=Element.get('speaker')
                    #print file_trs
                    has_attrib_speaker=True
                    spkr=spkr.split()[0]
                    #print spkr
                    # Get StartSegment
                    startTime = Element.get('startTime')
                    # Get EndSegment
                    endTime = Element.get('endTime')
                    # count sync for computing start and end utterance
                    Turn_count = Turn_count+1
        elif has_attrib_speaker:
            #print("Je rentre dans has_attrib_speaker et element.tail not null")
            #print(str(Element.tag))
            #print(str(Element.tail))
            if Element.tag=="Sync":
                #print("Je rentre Sync+Background"+ text +"| et le next c'est "+ Element.tail)
                #print(Element.tag+" "+Element.tail)
                Time_start_current_sync=Element.get('time')
                #if count>0:
                    #print("save after Turn")
                    #print(str(basename))
                    #print(str(section_topic))
                    #print(str(spkr))
                    #print(str(int(Turn_count)))
                    #print(str(int(count)))
                    #print text
                    ### Save Files For Kaldi ###
                seg_id = str(basename) + '_%s-%03d_Section%02d_Topic-%s_Turn-%03d_seg-%07d' % (
                str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)),int(nb_section),str(section_topic), int(Turn_count), int(count))
                spkr_id = str(basename)+'_%s-%03d' % (str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)))
                text = transformation_text(text)
                #print("Sync or Background: wizzz "+text)
                end_utt=Time_start_current_sync
                if text!="":
                    #print("SAVED BY SYNC or BACKGROUND "+seg_id+" "+text)
                    Spk_that_contribute_to_meeting.add(spkr)
                    #segments_file.write(seg_id+" "+basename+" "+str(start_utt)+" "+str(end_utt)+"\n")
                    #utt2spk_file.write(seg_id+" "+spkr_id+"\n")
                    #text_file.write(seg_id+" "+text+"\n")
                    print(text)
                    text=""
                    count+=1
                start_utt=Time_start_current_sync
                text=Element.tail.replace('\n', '')
                #print(count)
                #count+=1
            elif Element.tag=="Comment" or Element.tag=="Background":
                text=text+" "+Element.tail.replace('\n', '')
            elif Element.tag=="Event":
            #    if Element.get('type')=='noise':
                    # ===== Respiration
                if Element.get('desc')=='r' or Element.get('desc')=='i' or Element.get('desc')=='e' or Element.get('desc')=='n':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='pf':
                    text=text+" "+Element.tail.replace('\n', '')
                # ===== Bruits bouches
                elif Element.get('desc')=='tx':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='bg':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='bb':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='rire':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='sif':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='ch' or Element.get('desc')=='ch-':
                    text=text+" "+Element.tail.replace('\n', '')
                # ====== Bruit exterieus a l'acte de parole
                elif Element.get('desc')=='b' or Element.get('desc')=='pap' or Element.get('desc')=='mic' or Element.get('desc')=='conv':
                    text=text+" "+Element.tail.replace('\n', '')
                elif Element.get('desc')=='top':
                    text=text+" "+Element.tail.replace('\n', '')
                # "pi" intellegible "pif" inaudible voir doc transcriber
            #elif Element.get('type')=='pronounce':
            #    text=text+" "+Element.tail.replace('\n', '')
            # desc="EN"
            #if Element.get('type')=='language':
            #    text=text+" "+Element.tail.replace('\n', '')
            #if Element.tag=="Who":
                else:
                    text=text+" "+Element.tail.replace('\n', '')
    if count > 0 and has_attrib_speaker and not Element.tail is None:
        #print text
        ### Save Files For Kaldi ###
        seg_id = str(basename) + '_%s-%03d_Section%02d_Topic-%s_Turn-%03d_seg-%07d' % (
        str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)),int(nb_section),str(section_topic), int(Turn_count), int(count))
        #seg_id = str(basename) + '_spk-%03d_Turn-%03d_seg-%07d' % (
        #int(spkr.split('spk')[1]), int(Turn_count), int(count))
        spkr_id = str(basename)+'_%s-%03d' % (str(re.sub('\d+','',spkr)),int(re.sub('[a-zA-Z]','',spkr)))
        text = transformation_text(text)
        if bool and text != "":
            #print("Last SAVE"+seg_id+" "+text)
            #segments_file.write(seg_id+" "+basename+" "+str(start_utt)+" "+str(endTime)+"\n")
            #utt2spk_file.write(seg_id+" "+spkr_id+"\n")
            #text_file.write(seg_id+" "+text+"\n")
            print(text)
    # Gender file edition
    #print(Spk_that_contribute_to_meeting)
    #print(len(Spk_that_contribute_to_meeting))
    #print(speaker_gender)
    #print(len(speaker_gender))
    #for spk in speaker_gender:
    #    if spk[0] in Spk_that_contribute_to_meeting:
    #        spk_id = str(basename)+'_%s-%03d' % (str(re.sub('\d+','',spk[0])),int(re.sub('[a-zA-Z]','',spk[0])))
    #        spk2gender.write(spk_id+" "+spk[1]+"\n")
    #wav_scp.write(basename+" sox "+os.path.dirname(file_trs) + '/' + basename + '.wav'+" -t wav -r 16000 -c 1 - |\n")
    #segments_file.close()
    #utt2spk_file.close()
    #text_file.close()
    #wav_scp.close()
    #topic_file.close()
    #spk2gender.close()
