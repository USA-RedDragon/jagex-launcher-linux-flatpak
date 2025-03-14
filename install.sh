#!/bin/bash

set -euo pipefail

# renovate: datasource=git-tags versioning=regex depName=https://gitlab.com/freedesktop-sdk/freedesktop-sdk.git
FREEDESKTOP_SDK_GIT_VERSION=freedesktop-sdk-23.08.28
FREEDESKTOP_SDK_VERSION=$(echo ${FREEDESKTOP_SDK_GIT_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

HAS_NVIDIA=0
NVIDIA_DRIVER_PATH="/proc/driver/nvidia/version"
if [[ -f ${NVIDIA_DRIVER_PATH} ]]; then
    HAS_NVIDIA=1
    if grep "Open Kernel Module" ${NVIDIA_DRIVER_PATH}
    then
      NVIDIA_VERISON=$(cat ${NVIDIA_DRIVER_PATH} | head -n 1 | awk '{ print $10 }' | sed 's/\./-/g')
    else
      NVIDIA_VERISON=$(cat ${NVIDIA_DRIVER_PATH} | head -n 1 | awk '{ print $8 }' | sed 's/\./-/g')
    fi
fi

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists JagexLauncher https://jagexlauncher.flatpak.mcswain.dev/JagexLauncher.flatpakrepo

flatpak install --user -y --noninteractive flathub \
    org.freedesktop.Platform//${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Platform.Compat.i386/x86_64/${FREEDESKTOP_SDK_VERSION} \
    org.freedesktop.Platform.GL32.default/x86_64/${FREEDESKTOP_SDK_VERSION}

if [[ ${HAS_NVIDIA} -eq 1 ]]; then
    flatpak install --user -y --noninteractive flathub \
        org.freedesktop.Platform.GL.nvidia-${NVIDIA_VERISON}/x86_64 \
        org.freedesktop.Platform.GL32.nvidia-${NVIDIA_VERISON}/x86_64
fi

flatpak install --or-update --user -y --noninteractive JagexLauncher com.jagex.Launcher
