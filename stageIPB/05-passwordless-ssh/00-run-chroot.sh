#!/bin/bash -e

# remove password from user pi
passwd -d ${FIRST_USER_NAME}

# allow login to empty-password users
sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth

# allow ssh into the raspberry with empty passwords
sed -i -Ee 's/^#?[[:blank:]]*PermitEmptyPasswords[[:blank:]]*no[[:blank:]]*$/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

# Get rid of annoying banner
rm /usr/share/userconf-${FIRST_USER_NAME}/sshd_banner 2>/dev/null || true
