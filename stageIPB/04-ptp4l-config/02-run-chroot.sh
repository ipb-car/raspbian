#!/bin/bash -e

systemctl disable timemaster
systemctl enable ptp4l@eth0
