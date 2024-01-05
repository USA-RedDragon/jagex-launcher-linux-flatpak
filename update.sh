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
FREEDESKTOP_SDK_GIT_VERSION=freedesktop-sdk-23.08.9
FREEDESKTOP_SDK_VERSION=$(echo ${FREEDESKTOP_SDK_GIT_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

GL_VERSION=$(curl -fSsL 'https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/raw/master/elements/flatpak-images/sdk.bst?inline=false' | grep -A 10 'Extension org.freedesktop.Platform.GL:' | grep 'version:' | yq .version)
GL_VERSIONS="${FREEDESKTOP_SDK_VERSION};${GL_VERSION}"

# renovate: datasource=github-releases depName=USA-RedDragon/jagex-launcher
JAGEX_LAUNCHER_VERSION=0.31.0
JAGEX_LAUNCHER_URL=https://github.com/USA-RedDragon/jagex-launcher/releases/download/${JAGEX_LAUNCHER_VERSION}/launcher-${JAGEX_LAUNCHER_VERSION}.tar.gz
JAGEX_LAUNCHER_SHA256=$(curl -fSsL "${JAGEX_LAUNCHER_URL}" | sha256sum | cut -d' ' -f1)

# renovate: datasource=github-releases versioning=regex depName=GloriousEggroll/wine-ge-custom
WINE_GE_VERSION=GE-Proton8-25
WINE_GE_URL=https://github.com/GloriousEggroll/wine-ge-custom/releases/download/${WINE_GE_VERSION}/wine-lutris-${WINE_GE_VERSION}-x86_64.tar.xz
WINE_GE_SHA256=$(curl -fSsL "${WINE_GE_URL}" | sha256sum | cut -d' ' -f1)

# renovate: datasource=git-tags depName=https://gitlab.gnome.org/GNOME/libnotify.git
LIBNOTIFY_VERSION=0.8.3

# We need to check if the next version of HDOS exists since there is no API to get the latest version
HDOS_URL=https://cdn.hdos.dev/launcher/latest/hdos-launcher.jar
TEMPDIR=$(mktemp -d)
curl -fSsL "${HDOS_URL}" -o ${TEMPDIR}/hdos.jar
HDOS_SHA256=$(cat ${TEMPDIR}/hdos.jar | sha256sum | cut -d' ' -f1)
cd ${TEMPDIR}
unzip ${TEMPDIR}/hdos.jar META-INF/MANIFEST.MF
HDOS_VERSION=$(cat META-INF/MANIFEST.MF | grep Build-Revision | awk '{ print $2 }' | tr -d '\r')
cd -
rm -rf ${TEMPDIR}
HDOS_SHORT_VERSION=$(echo ${HDOS_VERSION} | awk -F. '{ print "v"$3 }')
HDOS_URL=https://cdn.hdos.dev/launcher/${HDOS_SHORT_VERSION}/hdos-launcher.jar

# renovate: datasource=github-releases depName=runelite/launcher
RUNELITE_LAUNCHER_VERSION=2.6.12
RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION=$(echo ${RUNELITE_LAUNCHER_VERSION} | cut -d'-' -f3 | cut -d'.' -f1-2)

# Runelite doesn't always update the JAR, so we need to search previous releases for the latest JAR
curVersion="${RUNELITE_LAUNCHER_VERSION}"
# We need to decrement the patch version until either a JAR is found or until "${RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION}.-1" is reached
while [[ "${curVersion}" != "${RUNELITE_LAUNCHER_MAJOR_MINOR_VERSION}.-1" ]]; do
    RUNELITE_URL="https://github.com/runelite/launcher/releases/download/${curVersion}/RuneLite.jar"
    if curl -fSsL "${RUNELITE_URL}" > /dev/null 2>&1; then
        break
    fi
    curVersion=$(semver_decrement_patch "${curVersion}")
done
RUNELITE_LAUNCHER_VERSION=$curVersion

RUNELITE_SHA256=$(curl -fSsL "${RUNELITE_URL}" | sha256sum | cut -d' ' -f1)

if ! xmlstarlet sel -Q -t -c "//component/releases/release[@version='${JAGEX_LAUNCHER_VERSION}']" ./resources/com.jagex.Launcher.metainfo.xml > /dev/null 2>&1;
then
    xmlstarlet ed -P -L -i '//component/releases/*' -t elem -n TMP -v '' \
        -i //TMP -t attr -n version -v "${JAGEX_LAUNCHER_VERSION}" \
        -i //TMP -t attr -n date -v "$(date '+%F')" \
        -r //TMP -v release \
        ./resources/com.jagex.Launcher.metainfo.xml
fi

if ! xmlstarlet sel -Q -t -c "//component/releases/release[@version='${RUNELITE_LAUNCHER_VERSION}']" ./resources/com.jagex.Launcher.ThirdParty.RuneLite.metainfo.xml;
then
    xmlstarlet ed -P -L -i '//component/releases/*' -t elem -n TMP -v '' \
        -i //TMP -t attr -n version -v "${RUNELITE_LAUNCHER_VERSION}" \
        -i //TMP -t attr -n date -v "$(date '+%F')" \
        -r //TMP -v release \
        ./resources/com.jagex.Launcher.ThirdParty.RuneLite.metainfo.xml
fi

if ! xmlstarlet sel -Q -t -c "//component/releases/release[@version='${HDOS_VERSION}']" ./resources/com.jagex.Launcher.ThirdParty.HDOS.metainfo.xml;
then
    xmlstarlet ed -P -L -i '//component/releases/*' -t elem -n TMP -v '' \
        -i //TMP -t attr -n version -v "${HDOS_VERSION}" \
        -i //TMP -t attr -n date -v "$(date '+%F')" \
        -r //TMP -v release \
        ./resources/com.jagex.Launcher.ThirdParty.HDOS.metainfo.xml
fi

yq ".x-runtime-version = \"${FREEDESKTOP_SDK_VERSION}\"" -i com.jagex.Launcher.yaml
yq ".sdk = \"org.freedesktop.Sdk//${FREEDESKTOP_SDK_VERSION}\"" -i com.jagex.Launcher.ThirdParty.HDOS.yaml
yq ".sdk = \"org.freedesktop.Sdk//${FREEDESKTOP_SDK_VERSION}\"" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
yq ".x-gl-version = \"${GL_VERSION}\"" -i com.jagex.Launcher.yaml
yq ".x-gl-versions = \"${GL_VERSIONS}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"jagex-launcher\") | .sources[0].url) = \"${JAGEX_LAUNCHER_URL}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"jagex-launcher\") | .sources[0].sha256) = \"${JAGEX_LAUNCHER_SHA256}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"runelite\") | .sources[0].url) = \"${RUNELITE_URL}\"" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
yq "(.modules.[] | select (.name == \"runelite\") | .sources[0].sha256) = \"${RUNELITE_SHA256}\"" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
yq "(.modules.[] | select (.name == \"hdos\") | .sources[0].url) = \"${HDOS_URL}\"" -i com.jagex.Launcher.ThirdParty.HDOS.yaml
yq "(.modules.[] | select (.name == \"hdos\") | .sources[0].sha256) = \"${HDOS_SHA256}\"" -i com.jagex.Launcher.ThirdParty.HDOS.yaml
yq "(.modules.[] | select (.name == \"wine\") | .sources[0].url) = \"${WINE_GE_URL}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"wine\") | .sources[0].sha256) = \"${WINE_GE_SHA256}\"" -i com.jagex.Launcher.yaml
yq "(.modules.[] | select (.name == \"libnotify\") | .sources[0].tag) = \"${LIBNOTIFY_VERSION}\"" -i com.jagex.Launcher.ThirdParty.RuneLite.yaml
