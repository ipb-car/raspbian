#!/bin/bash
# Inspired by https://github.com/lkwilson/auto-pi-gen

# Fetch the main raspbian git hash here
export GIT_HASH=${GIT_HASH:-"$(git rev-parse HEAD)"}

cd "$(dirname "$BASH_SOURCE")"

# Copy custom stages and config to pi-gen repo
cp -r stageIPB pi-gen/
cp -r config pi-gen/

# Remove exports
cd ./pi-gen
rm -f stage2/EXPORT_NOOBS

# Not clear from docs if this is needed besides what we say in the config file
touch ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
touch ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

# docker-build the custom pi gen
if [ -f ./config ]; then
  echo "Building custom ipb-raspbian image with config:"
  cat config
  ./build-docker.sh || {
    echo "Failed to build on ./config"
    exit 1
  }
fi
