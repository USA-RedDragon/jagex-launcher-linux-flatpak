#!/bin/bash

set -euo pipefail

__PWD=$(pwd)

TMPDIR=$(mktemp -d)
echo "Created temporary directory ${TMPDIR}"
trap "rm -rf ${TMPDIR}" EXIT INT TERM

# renovate: datasource=github-releases depName=runelite/launcher
RUNELITE_LAUNCHER_VERSION=2.6.12

curl -fSsL "https://raw.githubusercontent.com/runelite/launcher/${RUNELITE_LAUNCHER_VERSION}/runelite.ico" -o ${TMPDIR}/runelite.ico
cd ${TMPDIR}
convert runelite.ico runelite.png

if [[ ${__PWD} != */resources/icons/runelite ]]; then
    mkdir -p ${__PWD}/resources/icons/runelite
    cd ${__PWD}/resources/icons/runelite
else
    cd ${__PWD}
fi

cp -v ${TMPDIR}/runelite-0.png $(pwd)/16x16.png
cp -v ${TMPDIR}/runelite-1.png $(pwd)/24x24.png
cp -v ${TMPDIR}/runelite-2.png $(pwd)/32x32.png
cp -v ${TMPDIR}/runelite-3.png $(pwd)/48x48.png
cp -v ${TMPDIR}/runelite-4.png $(pwd)/128x128.png
