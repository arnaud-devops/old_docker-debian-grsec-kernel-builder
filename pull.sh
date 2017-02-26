#!/bin/bash

docker pull oxynux/debian-grsec-kernel-builder
docker run -itd --name debian-grsec-kernel-builder oxynux/debian-grsec-kernel-builder
docker cp debian-grsec-kernel-builder:/root/linux-kernel .
docker kill debian-grsec-kernel-builder
docker rm debian-grsec-kernel-builder
