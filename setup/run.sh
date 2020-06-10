#!/bin/bash
source ./config
docker run  --net=bridge -d -p 0.0.0.0:$SSH_PORT:22 -p 2026:2026 --rm --shm-size=$SHARED_MEMORY -v /mnt/data:/mnt/data -v /mnt/share:/mnt/share -v /home/:/mnt/home --gpus all -it --name $CONTAINER_NAME $IMAGE_NAME:latest /bin/bash -c '/usr/sbin/sshd -D&& tail -f /dev/null'
