# LinSTT Model Factory : ASR-Platform

Purpose
--------

We will describe how to build & use this ASR-Platform based-on Kaldi toolkit in the following three parts.

We assume that you are familiar with UNIX environments, scripting languages (bash, python, perl) & Kaldi Toolkit.

For all the theorical support of Automatic Speech Recognition, and for interested readers, please contact: [Abdel HEBA](mailto:aheba@linagora.com)

Docker Install
---------
For this project, you need to install [nvidia-docker](https://github.com/NVIDIA/nvidia-docker).

Becarful: if you use specific DNS in your server, you should add the DNS in your docker config.
```
# Check Server DNS:
nmcli dev show | grep 'IP4.DNS'
#IP4.DNS[1]:                             XXX.XXX.XXX.XXX
#IP4.DNS[2]:                             YYY.YYY.YYY.YYY
```
Turn off your docker service `systemctl stop docker.service`
Modify `/lib/systemd/system/docker.service` and replace `ExecStart=/usr/bin/dockerd -H fd://` with all your DNS IP `ExecStart=/usr/bin/dockerd --dns XXX.XXX.XXX.XXX --dns YYY.YYY.YYY.YYY -H fd://`


How to set-up & build our Docker
---------
We assume that you have technical minimum requierements [RAM 16GB,CPU 12, Hard Drive 500Gb, GPU [optional]: 1 Nvidia X Titan].
Using this [Dockerfile](https://github.com/linto-ai/linstt-factory/blob/master/Dockerfile), all packages and softwares (Kaldi toolkit....) needed for bulding Speech-To-Text system are pre-configured.

To build asr-platform docker :
```
nvidia-docker build -t linagora/asr_platform <Path_asr_project>
```
and for running the VM:
```
nvidia-docker run --rm -it -p $jupyter_port:8888 \
	      -v $path_shared/scripts:/opt/ASR_platform/scripts \
	      -v $path_shared/data:/opt/ASR_platform/data \
	      -v $path_shared/ASR_exp:/opt/ASR_platform/ASR_exp \
	      -v $path_shared/corpus:/opt/ASR_platform/corpus \
	      linagora/asr_platform
```
where <Jupyter-port-access> is the port acces to jupyter-notebook service, and <path_volume_shared> your current asr_dir ( every changes inside the docker will modify the files in your shared volume)

you can use `./start.sh $PWD <Jupyter-port-access>` to build and run docker

ASR Platform
---------
Our new version consist of splitting the training step by building a new architecture of kaldi receipe that help to have separate scripts for each models and then, compile system when all training steps were made.

```
├── Dockerfile                                  # Docker receipe
├── README.md                                   # Readme
├── requirements_pip3.txt                       # Dependecies for python3
├── requirements.txt                            # Dependecies for python2
├── scripts                                     # Scripts directory (All scripts to train & build asr system)
├── start.sh                                    # Build & Run docker
├── tools                                       # All tools that scripts need to work (Kaldi, g2p model...)
└── ASR_exp                                     # training repos                               
    └── dict                                     # Phonetic Lexicon (all phonetic extension will be there)
    └── exp_am                                      # Acoustic Modeling
    └── exp_lm                                      # Language Modeling
    └── ASR_sys                                      # STT system will compiled there
        
```
