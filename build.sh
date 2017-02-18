#!/bin/bash

docker build --no-cache -t debian-grsec-kernel-builder . | tee build.log
docker run -itd --name debian-grsec-kernel-builder debian-grsec-kernel-builder
docker cp debian-grsec-kernel-builder:/root/linux-kernel .
docker kill debian-grsec-kernel-builder
docker rm debian-grsec-kernel-builder
