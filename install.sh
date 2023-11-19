#!/bin/bash

set -euo pipefail

DESTDIR="$(realpath $1)"
JAGEX_LAUNCHER_LINUX_SHA=07972dae16b9d8abf6bcdf9a52d7a68e958f055d

OLDPWD="$PWD"

# If DESTDIR exists, delete it
if [ -d "${DESTDIR}" ]; then
    rm -rf "${DESTDIR}"
fi

mkdir -p "${DESTDIR}"

# If jagex-launcher-linux doesn't exist, clone it
if [ ! -d jagex-launcher-linux ]; then
    git clone https://github.com/TormStorm/jagex-launcher-linux.git jagex-launcher-linux
fi

cd jagex-launcher-linux

# If the git repo isn't clean, reset it
git reset --hard HEAD
git fetch --all
git checkout ${JAGEX_LAUNCHER_LINUX_SHA}

# If the venv doesn't exist, create it
if [ ! -d venv ]; then
    python3 -m venv venv
fi

# Install requirements
. venv/bin/activate
pip install -r resources/requirements.txt
cd "${OLDPWD}"

# Create a simple wineprefix
JAGEX_LAUNCHER_PATH="${DESTDIR}/drive_c/Program Files (x86)/Jagex Launcher"
mkdir -p "${JAGEX_LAUNCHER_PATH}"
cd "${JAGEX_LAUNCHER_PATH}"

python ${OLDPWD}/jagex-launcher-linux/resources/installer.py

deactivate
