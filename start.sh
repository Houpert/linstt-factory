# Args: <root_path> <jupyter_port>
root_path=$1
jupyter_port=$2

# Build docker
docker build -t linagora/asr_platform .

# Run Dokcer with shared directory
docker run --rm -it -p $jupyter_port:8888 \
	      -v $path_shared/scripts:/opt/ASR_platform/scripts \
	      -v $path_shared/data:/opt/ASR_platform/data \
	      -v $path_shared/ASR_exp:/opt/ASR_platform/ASR_exp \
	      -v $path_shared/corpus:/opt/ASR_platform/corpus \
	      linagora/asr_platform
