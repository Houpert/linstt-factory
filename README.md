# LinSTT Model Factory : ASR-Platform

Purpose
--------

We will describe how to build & use this ASR-Platform based-on Kaldi toolkit in the following three parts.

We assume that you are familiar with UNIX environments, scripting languages (bash, python, perl).

For all the theorical support of Automatic Speech Recognition, and for interested readers, please contact: [Abdel HEBA](mailto:aheba@linagora.com)

Docker Install
---------
For this project, you need to install [nvidia-docker](https://github.com/NVIDIA/nvidia-docker).

Becarful: if you use specific DNS in your server, you should add the DNS in your docker config.
```
# Check Server DNG:
nmcli dev show | grep 'IP4.DNS'
#IP4.DNS[1]:                             141.115.4.41
#IP4.DNS[2]:                             141.115.4.42
```
Modify `/lib/systemd/system/docker.service` and replace `ExecStart=/usr/bin/dockerd -H fd://` with all your DNS IP `ExecStart=/usr/bin/dockerd --dns 141.115.4.42 --dns 141.115.4.41 -H fd://`


How to set-up & build our Docker
---------
We assume that you have technical minimum requierements [RAM 16GB,CPU 12, Hard Drive 500Gb, GPU [optional]: 1 Nvidia X Titan].
Using this [Dockerfile](https://ci.linagora.com/aheba/kaldi_gen_new/blob/master/Dockerfile), all packages and softwares (Kaldi toolkit....) needed for bulding Speech-To-Text system are pre-configured.

To build asr-platform docker :
```
nvidia-docker build -t linagora/asr_platform <Path_asr_project>
```
and for running the VM:
```
nvidia-docker run --rm -it -p <Jupyter-port-access>:8888 -v <path_volume_shared>:/opt/lvcsrPlatform linagora/asr_platform
```
where <Jupyter-port-access> is the port acces to jupyter-notebook service, and <path_volume_shared> your current asr_dir ( every changes inside the docker will modify the files in your shared volume)

you can use `./start.sh $PWD <Jupyter-port-access>` to build and run docker

ASR Platform
---------
Our new version consist of splitting the training step by building a new architecture of kaldi receipe that help to have separate scripts for each models and then, compile system when all training steps were made.

```
├── Dockerfile                                  # Docker receipe
├── README.md                                   
├── requirements_pip3.txt                       # Dependecies for python3
├── requirements.txt                            # Dependecies for python2
├── scripts                                     # Scripts directory (All scripts to train & compile system are here)
├── start.sh                                    # Build & Run docker
├── tmp                                         # Some input example for training language model & add specific terms to pronunciation model
├── tools                                       # All tools that scripts need to work (Kaldi, g2p model...)
├── system                                      # STT system will compiled there
└── training                                    # training data                                    
    └── LEX                                     # Phonetic Lexicon
    └── AM                                      # Acoustic Modeling
    └── LM                                      # Language Modeling
        
```

Speech-to-Text Run example V0
---------
For this first V0, we propose an example of :
- Training language model from text input
- Add phonetic from new terms that doesn't appear in basic dictionary

To run this example:
- Build & Run `./start $PWD 8080`
- Connect to Jupyter-notebook service with Browser using `http://<IP_SERVER>:8080`
- Copy the jupyter token from the terminal and connect
- Go to `scripts/SYS_V0.ipynb`
- Run the script and Enjoy :)