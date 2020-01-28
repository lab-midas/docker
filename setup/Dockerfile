#FROM anibali/pytorch:cuda-10.1
#FROM nvidia/cuda:10.1-base-ubuntu18.04
# https://github.com/anibali/docker-pytorch
ARG UBUNTU_VERSION=18.04

ARG ARCH=
ARG CUDA=10.0
FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION} as base
# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.4.38-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=6.0.1-1
ARG LIBNVINFER_MAJOR_VERSION=6

USER root

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        libcublas10 \
        libcublas-dev \
        cuda-cudart-dev-${CUDA/./-} \
        cuda-cufft-dev-${CUDA/./-} \
        cuda-curand-dev-${CUDA/./-} \
        cuda-cusolver-dev-${CUDA/./-} \
        cuda-cusparse-dev-${CUDA/./-} \
        libcudnn7=${CUDNN}+cuda${CUDA} \
        libcudnn7-dev=${CUDNN}+cuda${CUDA} \
        libcurl3-dev \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        git \
	curl \
	ca-certificates \
	sudo \
	bzip2 \
	libx11-6 \
        && \
    find /usr/local/cuda-${CUDA}/lib64/ -type f -name 'lib*_static.a' -not -name 'libcudart_static.a' -delete && \
    rm /usr/lib/${LIB_DIR_PREFIX}-linux-gnu/libcudnn_static_v7.a

# Install TensorRT if not building for PowerPC
RUN [[ "${ARCH}" = "ppc64le" ]] || { apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-dev=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin-dev=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; }

# Configure the build for our CUDA configuration.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:/usr/include/x64_64-linux-gnu:$LD_LIBRARY_PATH
ENV TF_NEED_CUDA 1
ENV TF_NEED_TENSORRT 1
ENV TF_CUDA_VERSION=${CUDA}
ENV TF_CUDNN_VERSION=${CUDNN_MAJOR_VERSION}
# CACHE_STOP is used to rerun future commands, otherwise cloning tensorflow will be cached and will not pull the most recent version
ARG CACHE_STOP=1
# Check out TensorFlow source code if --build-arg CHECKOUT_TF_SRC=1
ARG CHECKOUT_TF_SRC=0
RUN test "${CHECKOUT_TF_SRC}" -eq 1 && git clone https://github.com/tensorflow/tensorflow.git /tensorflow_src || true

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig

# user management
RUN  addgroup --gid 1004 ubuntu
RUN  adduser --uid 1002 --disabled-password --gecos "" --force-badname --gid 1004 ubuntu
RUN  /bin/bash -c "echo 'ubuntu:midas' | chpasswd"
RUN  usermod -aG sudo ubuntu
RUN  addgroup --gid 1001 sharegrp
RUN  addgroup --gid 1002 datagrp
RUN  usermod -aG sharegrp ubuntu
RUN  usermod -aG datagrp ubuntu

# install SSH server
RUN  apt-get update && apt-get install -y openssh-server
RUN  mkdir -p /var/run/sshd
RUN  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN  sed -i 's/\/usr\/lib\/openssh\/sftp-server/internal-sftp/' /etc/ssh/sshd_config
RUN  sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN  sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22

# Install some tools
RUN  apt-get update -y
RUN  apt-get install -y nano
RUN  apt-get install -y vim
RUN  apt-get install -y tmux
RUN  apt-get install -y qt5-default

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -y install make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

USER ubuntu
ARG  HOME=/home/ubuntu
ENV  PATH=$HOME/.pyenv/bin:$PATH
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
RUN echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> $HOME/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc
RUN echo 'eval "$(pyenv virtualenv-init -)"' >> $HOME/.bashrc
RUN echo "set-option -g update-environment \"SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY\"" >> ~/.tmux.conf

# set env variables manually, sometimes .bashrc is not used
RUN eval "$(pyenv init -)"
RUN eval "$(pyenv virtualenv-init -)"

# Install python version
RUN pyenv install 3.7.4
RUN pyenv global 3.7.4

# Install pip packages
ADD requirements.txt /home/ubuntu/requirements.txt
RUN /home/ubuntu/.pyenv/versions/3.7.4/bin/pip install --upgrade pip
RUN /home/ubuntu/.pyenv/versions/3.7.4/bin/pip install -r /home/ubuntu/requirements.txt

USER root
#CMD ["/bin/bash", "-D"]
#CMD tail -f /dev/null
