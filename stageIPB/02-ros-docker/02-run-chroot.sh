#!/bin/bash -e

# Install docker, if not present (incremental builds)
if ! command -v docker >/dev/null 2>&1; then
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	rm /get-docker.sh

	# Add pi to docker group
	usermod -aG docker ${FIRST_USER_NAME}

	cd /home/${FIRST_USER_NAME}
	bash download-frozen-image-v2.sh docker_image prbonn/pi_ros:latest
fi

# Change the ownership of the scripts I hope we get rid of soon
chown -R 1000:1000 /home/pi/download-frozen-image-v2.sh
chown -R 1000:1000 /home/pi/ipbcar_docker.sh
chown -R 1000:1000 /home/pi/docker_image/

# Enable docker service on boot
systemctl daemon-reload
systemctl enable ipbcar_docker.service
