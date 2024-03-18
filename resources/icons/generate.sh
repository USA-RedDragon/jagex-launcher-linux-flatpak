#!/bin/bash

set -euo pipefail

# renovate: datasource=github-releases depName=USA-RedDragon/jagex-launcher
JAGEX_LAUNCHER_VERSION=0.33.0

__PWD=$(pwd)

TMPDIR=$(mktemp -d)
echo "Created temporary directory ${TMPDIR}"
trap "rm -rf ${TMPDIR}" EXIT INT TERM

curl -fSsL https://github.com/USA-RedDragon/jagex-launcher/releases/download/${JAGEX_LAUNCHER_VERSION}/launcher-${JAGEX_LAUNCHER_VERSION}.tar.gz | tar -C ${TMPDIR} -xzf -
cd ${TMPDIR}

wrestool -x --output=icon.ico -t14 JagexLauncher.exe
convert icon.ico icon.png

if [[ ${__PWD} != */resources/icons ]]; then
    mkdir -p ${__PWD}/resources/icons
    cd ${__PWD}/resources/icons
else
    cd ${__PWD}
fi

cp -v ${TMPDIR}/icon-0.png $(pwd)/16x16.png
cp -v ${TMPDIR}/icon-1.png $(pwd)/32x32.png
cp -v ${TMPDIR}/icon-2.png $(pwd)/48x48.png
cp -v ${TMPDIR}/icon-3.png $(pwd)/64x64.png
cp -v ${TMPDIR}/icon-4.png $(pwd)/128x128.png
cp -v ${TMPDIR}/icon-5.png $(pwd)/256x256.png
