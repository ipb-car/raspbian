# ipb-Raspbian image generator

For the official documentation of the pi-gen please check the official [README](./pi-gen/README.md). You should read at least ONCE that readme to make sure what you are doing.


## How to build

```sh
sudo ./build.sh
```

## How to build incrementally

Make sure you build at least up the the pi-gen stages, and then run this command to skip re-building of those layers:

```sh
touch pi-gen/stage0/SKIP pi-gen/stage1/SKIP pi-gen/stage2/SKIP 
```

## How to build incrementally, cleaning the stage

If you don't specify it, then incremental build will reuse the last generated file system. Meaning that you might end up with duplicated configurations, etc. If you don't know how to create idempotent scripts (which seems to be the case) then just run this command for incremental builds:

```sh
sudo CLEAN=1 ./build.sh
```

## stageIPB documentation

This has been work in progress since years, but I hope that the now new thin layer [stageIPB](./stageIPB) it is easier to follow. Hopefully soon everything will be **properly** migrated to docker and that stage shall only configure the boot overall for routing the pins in the pi hardware.

## Fucked up!?

Then just reset the repo:

```sh
./reset.sh
```

## What about docker

Don't user docker for building the image as it requires doing it always from scratch.
