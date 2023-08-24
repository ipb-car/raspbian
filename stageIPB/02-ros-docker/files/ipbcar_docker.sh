#!/usr/bin/env bash
tar -cC '/home/pi/docker_image' . | docker load
docker run \
	--name docker_pi \
	--device=/dev/ttyUSB0 \
	--group-add dialout \
	--network host \
	-v /etc/localtime:/etc/localtime:ro \
	-d --rm -ti prbonn/pi_ros:latest
