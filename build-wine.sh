#!/bin/bash

set -euo pipefail

DESTDIR="$(realpath $1)"

OLDPWD="$PWD"

# renovate: datasource=git-tags depName=https://gitlab.winehq.org/wine/wine
WINE_VERSION=wine-8.20

# If OLDPWD/wine doesn't exist, clone it
if [ ! -d wine-src ]; then
    git clone -b ${WINE_VERSION} https://gitlab.winehq.org/wine/wine.git wine-src
fi

cd wine-src
git reset --hard HEAD
git fetch --all
git checkout ${WINE_VERSION}
cd -

docker build -t wine-build -f Dockerfile.wine wine-src

# If DESTDIR exists, exit silently
if [ -d "${DESTDIR}" ]; then
    exit 0
fi

mkdir -p "${DESTDIR}"
docker run --rm -v "${DESTDIR}:/wine-build" --user $(id -u):$(id -g) -i wine-build bash <<EOF
set -euo pipefail
echo UNAME=\$(uname -a)
echo USER=\$(id):\$(id -g)
echo PWD=\$(pwd)
echo LIBC_VERSION=\$(ldd --version)
EOF
