#!/bin/bash

set -euo pipefail

# Dosign should be 1 if $1 is set
DOSIGN=0
if [[ ! -z ${1+x} ]]; then
    DOSIGN=1
fi

# renovate: datasource=git-tags depName=https://gitlab.com/freedesktop-sdk/freedesktop-sdk.git
FREEDESKTOP_SDK_GIT_VERSION=freedesktop-sdk-23.08.6
FREEDESKTOP_SDK_VERSION=$(echo ${FREEDESKTOP_SDK_GIT_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

HAS_NVIDIA=0
if [[ -f /proc/driver/nvidia/version ]]; then
    HAS_NVIDIA=1
    NVIDIA_VERISON=$(cat /proc/driver/nvidia/version | head -n 1 | awk '{ print $8 }' | sed 's/\./-/g')
fi

# If icons doesn't exist, generate them
if [[ ! -f resources/icons/256x256.png ]]; then
    ./resources/icons/generate.sh
fi

flatpak install --user -y --noninteractive flathub \
    org.freedesktop.Platform//${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Sdk//${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Sdk.Compat.i386/x86_64/${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Sdk.Extension.toolchain-i386/x86_64/${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Sdk.Extension.mingw-w64/x86_64/${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Platform.Compat.i386/x86_64/${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Platform.GL32.default/x86_64/${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Platform.GL.default/x86_64/${FREEDESKTOP_SDK_VERSION}

if [[ ${HAS_NVIDIA} -eq 1 ]]; then
    flatpak install --user -y --noninteractive flathub \
        org.freedesktop.Platform.GL.nvidia-${NVIDIA_VERISON}/x86_64 \
        org.freedesktop.Platform.GL32.nvidia-${NVIDIA_VERISON}/x86_64
fi

REPO_ARGS=""
GPG_ARGS=""
if [[ ${DOSIGN} -eq 1 ]]; then
    REPO_ARGS="--repo ./repo"
    GPG_ARGS="--gpg-sign=7ADE1CA57A2E2272"
fi

flatpak-builder ${REPO_ARGS} ${GPG_ARGS} --default-branch=stable --user --ccache --force-clean out com.jagex.Launcher.yaml
if [[ ${DOSIGN} -eq 0 ]]; then
    flatpak build-export repo out stable
fi
flatpak build-update-repo ${GPG_ARGS} repo --title="Jagex Launcher" --generate-static-deltas --default-branch=stable

flatpak build-bundle ${GPG_ARGS} --repo-url=https://jagexlauncher.flatpak.mcswain.dev --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo repo com.jagex.Launcher.flatpak com.jagex.Launcher stable &
PID=$!

COUNTER=0
# Timeout after 1 hour
MAX_COUNTER=3600
while kill -0 $PID 2> /dev/null; do
    NUM_DOT=$((COUNTER%5))
    DOTS=$(printf '.%.0s' $(seq 0 $NUM_DOT))
    # Overwrite the line
    echo "Exporting flatpak${DOTS}"
    COUNTER=$((COUNTER+1))
    if [[ ${COUNTER} -gt ${MAX_COUNTER} ]]; then
        echo "Timed out after 1 hour"
        exit 1
    fi
    sleep 1
done

# Check exit code
wait $PID
if [[ $? -ne 0 ]]; then
    echo "Failed to export flatpak"
    exit 1
fi

echo "Built flatpak to com.jagex.Launcher.flatpak"
