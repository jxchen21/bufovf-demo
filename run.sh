#!/bin/bash

IMAGE="bufovf-demo"
PLATFORM="linux/amd64"

if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "[*] Image not found, building..."
    docker build --platform "$PLATFORM" -t "$IMAGE" .
else
    echo "[*] Image already exists, skipping build..."
fi

docker run --rm \
           --platform "$PLATFORM" \
           --security-opt seccomp=unconfined \
           --cap-add=SYS_PTRACE \
           -v "${PWD}:/bufovf-demo" \
           -it "$IMAGE" setarch -R bash