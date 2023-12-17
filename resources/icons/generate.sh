#!/bin/bash

set -euo pipefail

if [[ ! -f resources/icons/jagex-launcher/256x256.png ]]; then
    ./resources/icons/jagex-launcher/generate.sh
fi

if [[ ! -f resources/icons/hdos/512x512.png ]]; then
    curl -fSsL https://hdos.dev/logo.png -o resources/icons/hdos/512x512.png
fi

if [[ ! -f resources/icons/runelite/128x128.png ]]; then
    ./resources/icons/runelite/generate.sh
fi
