#!/bin/bash -e
if ! grep -q "COMMIT_HASH" /etc/os-release; then
	echo 'COMMIT_HASH='$GIT_HASH >>/etc/os-release
fi
echo '/etc/os-release content:'
cat /etc/os-release
