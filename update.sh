#!/bin/bash

set -euo pipefail

# This utility function decrements a semver patch version. I.e. 1.2.3 -> 1.2.2.
function semver_decrement_patch() {
  local version=$1
  local patch=$(echo "${version}" | cut -d'.' -f3)
  local patch_decremented=$((patch - 1))
  echo "${version}" | sed "s/${patch}/${patch_decremented}/"
}

# renovate: datasource=git-tags versioning=regex depName=https://gitlab.com/freedesktop-sdk/freedesktop-sdk.git
FREEDESKTOP_SDK_GIT_VERSION=freedesktop-sdk-23.08.8
FREEDESKTOP_SDK_VERSION=$(echo ${FREEDESKTOP_SDK_GIT_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

GL_VERSION=$(curl -fSsL 'https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/raw/master/elements/flatpak-images/sdk.bst?inline=false' | grep -A 10 'Extension org.freedesktop.Platform.GL:' | grep 'version:' | yq .version)
GL_VERSIONS="${FREEDESKTOP_SDK_VERSION};${GL_VERSION}"

# renovate: sha: datasource=git-refs depName=jagex-launcher-linux packageName=https://github.com/TormStorm/jagex-launcher-linux branch=main
JAGEX_LAUNCHER_LINUX_SHA=ed1164314472950d6dfea744e5071b244b70277d

# renovate: datasource=github-releases versioning=regex depName=GloriousEggroll/wine-ge-custom
WINE_GE_VERSION=GE-Proton8-25
WINE_GE_URL=https://github.com/GloriousEggroll/wine-ge-custom/releases/download/${WINE_GE_VERSION}/wine-lutris-${WINE_GE_VERSION}-x86_64.tar.xz
WINE_GE_SHA256=$(curl -fSsL "${WINE_GE_URL}" | sha256sum | cut -d' ' -f1)

HDOS_VERSION=v8

# We need to check if the next version of HDOS exists since there is no API to get the latest version
NEXT_HDOS_VERSION=v$(echo "${HDOS_VERSION}" | sed 's/v//g' | awk -F. -v OFS=. '{$NF++;print}')
HDOS_URL=https://cdn.hdos.dev/launcher/${NEXT_HDOS_VERSION}/hdos-launcher.jar
if curl -fSsL "${HDOS_URL}" > /dev/null; then
    echo "Found Newer HDOS JAR at ${HDOS_URL}"
    HDOS_VERSION="${NEXT_HDOS_VERSION}"
    # Self-edit this script to update the HDOS_VERSION variable
    sed -i "s/HDOS_VERSION=v.*/HDOS_VERSION=${HDOS_VERSION}/g" update.sh
fi
HDOS_URL=https://cdn.hdos.dev/launcher/${HDOS_VERSION}/hdos-launcher.jar
HDOS_SHA256=$(curl -fSsL "${HDOS_URL}" | sha256sum | cut -d' ' -f1)

# renovate: datasource=github-releases depName=runelite/launcher
RUNELITE_LAUNCHER_VERSION=2.6.11
RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION=$(echo ${RUNELITE_LAUNCHER_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

# Runelite doesn't always update the JAR, so we need to search previous releases for the latest JAR
curVersion="${RUNELITE_LAUNCHER_VERSION}"
# We need to decrement the patch version until either a JAR is found or until "${RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION}.-1" is reached
while [[ "${curVersion}" != "${RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION}.-1" ]]; do
    RUNELITE_URL="https://github.com/runelite/launcher/releases/download/${curVersion}/RuneLite.jar"
    if curl -fSsL "${RUNELITE_URL}" > /dev/null; then
        break
    fi
    curVersion=$(semver_decrement_patch "${curVersion}")
done

RUNELITE_SHA256=$(curl -fSsL "${RUNELITE_URL}" | sha256sum | cut -d' ' -f1)

yq ".x-runtime-version = \"${FREEDESKTOP_SDK_VERSION}\"" -i com.jagex.Launcher.yaml
yq ".x-gl-version = \"${GL_VERSION}\"" -i com.jagex.Launcher.yaml
yq ".x-gl-versions = \"${GL_VERSIONS}\"" -i com.jagex.Launcher.yaml
yq ".x-jagex-launcher-linux-sha = \"${JAGEX_LAUNCHER_LINUX_SHA}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"runelite\") | .sources[0].url) = \"${RUNELITE_URL}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"runelite\") | .sources[0].sha256) = \"${RUNELITE_SHA256}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"hdos\") | .sources[0].url) = \"${HDOS_URL}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"hdos\") | .sources[0].sha256) = \"${HDOS_SHA256}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"wine\") | .sources[0].url) = \"${WINE_GE_URL}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"wine\") | .sources[0].sha256) = \"${WINE_GE_SHA256}\"" -i com.jagex.Launcher.yaml
