#!/bin/bash -e

install -m 644 files/ipbcar_docker.service "${ROOTFS_DIR}/etc/systemd/system/ipbcar_docker.service"
install -m 644 files/download-frozen-image-v2.sh "${ROOTFS_DIR}/home/pi/download-frozen-image-v2.sh"
install -m 644 files/ipbcar_docker.sh "${ROOTFS_DIR}/home/pi/ipbcar_docker.sh"
