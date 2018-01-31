# Args: <Path_shared_directory>
path_shared=$1
jupyter_port=$2

# Build docker
nvidia-docker build -t linagora/asr_platform .

# Run Dokcer with shared directory
nvidia-docker run --rm -it -p $jupyter_port:8888 -v $path_shared/scripts:/opt/lvcsrPlatform/scripts -v $path_shared/training:/opt/lvcsrPlatform/training linagora/asr_platform
