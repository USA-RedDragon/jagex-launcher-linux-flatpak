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
FREEDESKTOP_SDK_GIT_VERSION=freedesktop-sdk-23.08.12
export FREEDESKTOP_SDK_VERSION=$(echo ${FREEDESKTOP_SDK_GIT_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

export GL_VERSION=$(curl -fSsL 'https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/raw/master/elements/flatpak-images/sdk.bst?inline=false' | grep -A 10 'Extension org.freedesktop.Platform.GL:' | grep 'version:' | yq .version)
export GL_VERSIONS="${FREEDESKTOP_SDK_VERSION};${GL_VERSION}"

# renovate: datasource=github-releases depName=USA-RedDragon/jagex-launcher
JAGEX_LAUNCHER_VERSION=0.32.0
export JAGEX_LAUNCHER_VERSION
export JAGEX_LAUNCHER_URL=https://github.com/USA-RedDragon/jagex-launcher/releases/download/${JAGEX_LAUNCHER_VERSION}/launcher-${JAGEX_LAUNCHER_VERSION}.tar.gz
export JAGEX_LAUNCHER_SHA256=$(curl -fSsL "${JAGEX_LAUNCHER_URL}" | sha256sum | cut -d' ' -f1)

# renovate: datasource=git-tags depName=https://gitlab.winehq.org/wine/wine
WINE_VERSION=wine-8.20
export WINE_VERSION

RS3_PKG_URL=https://content.runescape.com/downloads/ubuntu/dists/trusty/non-free/binary-amd64/Packages
RS3_FILENAME="$(curl -fSsL ${RS3_PKG_URL} | grep Filename | awk '{ print $2 }')"
export RS3_DEB_URL=https://content.runescape.com/downloads/ubuntu/${RS3_FILENAME}
export RS3_DEB_SHA256="$(curl -fSsL ${RS3_PKG_URL} | grep SHA256 | awk '{ print $2 }')"

# renovate: datasource=git-tags extractVersion=^OpenSSL_(?<major>\d+)_(?<minor>\d+)_(?<patch>\d+)(?<compatibility>[a-z]+) depName=https://github.com/openssl/openssl.git
export OPENSSL_VERSION=OpenSSL_1_1_1w

# renovate: datasource=git-tags depName=https://gitlab.gnome.org/GNOME/libnotify.git
LIBNOTIFY_VERSION=0.8.3
export LIBNOTIFY_VERSION

# We need to check if the next version of HDOS exists since there is no API to get the latest version
HDOS_URL=https://cdn.hdos.dev/launcher/latest/hdos-launcher.jar
TEMPDIR=$(mktemp -d)
curl -fSsL "${HDOS_URL}" -o ${TEMPDIR}/hdos.jar
export HDOS_SHA256=$(cat ${TEMPDIR}/hdos.jar | sha256sum | cut -d' ' -f1)
cd ${TEMPDIR}
unzip ${TEMPDIR}/hdos.jar META-INF/MANIFEST.MF
export HDOS_VERSION=$(cat META-INF/MANIFEST.MF | grep Build-Revision | awk '{ print $2 }' | tr -d '\r')
cd -
rm -rf ${TEMPDIR}
HDOS_SHORT_VERSION=$(echo ${HDOS_VERSION} | awk -F. '{ print "v"$3 }')
export HDOS_URL=https://cdn.hdos.dev/launcher/${HDOS_SHORT_VERSION}/hdos-launcher.jar

# renovate: datasource=github-releases depName=runelite/launcher
RUNELITE_LAUNCHER_VERSION=2.6.13
RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION=$(echo ${RUNELITE_LAUNCHER_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

# Runelite doesn't always update the JAR, so we need to search previous releases for the latest JAR
curVersion="${RUNELITE_LAUNCHER_VERSION}"
# We need to decrement the patch version until either a JAR is found or until "${RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION}.-1" is reached
while [[ "${curVersion}" != "${RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION}.-1" ]]; do
    export RUNELITE_URL="https://github.com/runelite/launcher/releases/download/${curVersion}/RuneLite.jar"
    if curl -fSsL "${RUNELITE_URL}" > /dev/null 2>&1; then
        break
    fi
    curVersion=$(semver_decrement_patch "${curVersion}")
done
export RUNELITE_LAUNCHER_VERSION=$curVersion

export RUNELITE_SHA256=$(curl -fSsL "${RUNELITE_URL}" | sha256sum | cut -d' ' -f1)

if ! yq -e '.component.releases.[][] | select(.+@version == strenv(JAGEX_LAUNCHER_VERSION))' ./resources/com.jagex.Launcher.metainfo.xml > /dev/null 2>&1;
then
    yq -i '.component.releases.release |= [{"+@version": strenv(JAGEX_LAUNCHER_VERSION), "+@date": now | format_datetime("2006-01-02")}] + .' ./resources/com.jagex.Launcher.metainfo.xml
fi

if ! yq -o yaml -e '.component.releases.[][] | select(.+@version == strenv(RUNELITE_LAUNCHER_VERSION))' ./resources/com.jagex.Launcher.ThirdParty.RuneLite.metainfo.xml > /dev/null 2>&1;
then
    yq -i '.component.releases.release |= [{"+@version": strenv(RUNELITE_LAUNCHER_VERSION), "+@date": now | format_datetime("2006-01-02")}] + .' ./resources/com.jagex.Launcher.ThirdParty.RuneLite.metainfo.xml
fi

if ! yq -e '.component.releases.[][] | select(.+@version == strenv(HDOS_VERSION))' ./resources/com.jagex.Launcher.ThirdParty.HDOS.metainfo.xml > /dev/null 2>&1;
then
    yq -i '.component.releases.release |= [{"+@version": strenv(HDOS_VERSION), "+@date": now | format_datetime("2006-01-02")}] + .' ./resources/com.jagex.Launcher.ThirdParty.HDOS.metainfo.xml
fi

yq ".x-runtime-version = strenv(FREEDESKTOP_SDK_VERSION)" -i com.jagex.Launcher.yaml
yq ".sdk = \"org.freedesktop.Sdk//\" + strenv(FREEDESKTOP_SDK_VERSION)" -i com.jagex.Launcher.ThirdParty.HDOS.yaml
yq ".sdk = \"org.freedesktop.Sdk//\" + strenv(FREEDESKTOP_SDK_VERSION)" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
yq ".x-gl-version = strenv(GL_VERSION)" -i com.jagex.Launcher.yaml
yq ".x-gl-versions = strenv(GL_VERSIONS)" -i com.jagex.Launcher.yaml
yq ".x-wine-version = strenv(WINE_VERSION)" -i com.jagex.Launcher.yaml
yq ".x-openssl-tag = strenv(OPENSSL_VERSION)" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"jagex-launcher\") | .sources[0].url) = strenv(JAGEX_LAUNCHER_URL)" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"jagex-launcher\") | .sources[0].sha256) = strenv(JAGEX_LAUNCHER_SHA256)" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"rs3-client\") | .sources[0].url) = strenv(RS3_DEB_URL)" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"rs3-client\") | .sources[0].sha256) = strenv(RS3_DEB_SHA256)" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"runelite\") | .sources[0].url) = strenv(RUNELITE_URL)" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
yq "(.modules.[] | select (.name == \"runelite\") | .sources[0].sha256) = strenv(RUNELITE_SHA256)" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
yq "(.modules.[] | select (.name == \"hdos\") | .sources[0].url) = strenv(HDOS_URL)" -i com.jagex.Launcher.ThirdParty.HDOS.yaml
yq "(.modules.[] | select (.name == \"hdos\") | .sources[0].sha256) = strenv(HDOS_SHA256)" -i com.jagex.Launcher.ThirdParty.HDOS.yaml
yq "(.modules.[] | select (.name == \"libnotify\") | .sources[0].tag) = strenv(LIBNOTIFY_VERSION)" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
