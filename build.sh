#!/bin/bash
# Inspired by https://github.com/lkwilson/auto-pi-gen

# Fetch the main raspbian git hash here
export GIT_HASH=${GIT_HASH:-"$(git rev-parse HEAD)"}

cd "$(dirname "$BASH_SOURCE")"

# Clean previous build in case this was thre
rm -rf pi-gen/stageIPB 2>/dev/null || true
rm -rf pi-gen/config 2>/dev/null || true

# Copy custom stages and config to pi-gen repo
cp -r stageIPB pi-gen/
cp -r config pi-gen/

# Remove exports
cd ./pi-gen
rm -f stage2/EXPORT_NOOBS

# Not clear from docs if this is needed besides what we say in the config file
touch ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
touch ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

if [ ! -f /proc/sys/fs/binfmt_misc/register ]; then
  echo "binfmt_misc required but not mounted, trying to mount it..."
  if ! mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc ; then
      echo "mounting binfmt_misc failed"
      exit 1
  fi
  echo "binfmt_misc mounted"
fi

# docker-build the custom pi gen
if [ -f ./config ]; then
  echo "Building custom ipb-raspbian image with config:"
  cat config
  ./build.sh || {
    echo "Failed to build on ./config"
    exit 1
  }
fi
