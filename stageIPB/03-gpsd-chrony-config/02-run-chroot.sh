#!/bin/bash -e

# Disable serial connection to allow GPS to use those pins
sudo systemctl disable hciuart
systemctl disable serial-getty@ttyS0.service
sed -e "s/console=serial0,115200 //g" -i /boot/cmdline.txt

# Route GPS hardware to the right pins, disable bluetooth
echo 'dtoverlay=disable-bt' | tee -a /boot/config.txt
echo 'dtoverlay=pps-gpio,gpiopin=18' | tee -a /boot/config.txt
echo 'enable_uart=1' | tee -a /boot/config.txt

# Load custom kernel modules for PPS
echo 'pps-gpio' | tee -a /etc/modules

# Chrony custom configuration
echo 'refclock PPS /dev/pps0 lock GPS' | tee -a /etc/chrony/chrony.conf
echo 'refclock SHM 0 refid GPS noselect' | tee -a /etc/chrony/chrony.conf

# Enable gpsd
systemctl enable gpsd
