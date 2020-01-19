#!/bin/bash
source ./config
docker run -d -p $PORT:22 --shm-size=$SHARED_MEMORY -v /mnt/data:/mnt/data -v /mnt/share:/mnt/share -v /home/:/mnt/home --gpus all -it --user $USER --name $CONTAINER_NAME $IMAGE_NAME:latest /bin/bash -c '/usr/sbin/sshd -D&& tail -f /dev/null'
