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
# if [ -d "${DESTDIR}" ]; then
#     exit 0
# fi

mkdir -p "${DESTDIR}"
docker run --rm -v "${DESTDIR}:/wine-build/out" -v "${HOME}/.cache/ccache:/ccache" -e ID=$(id -u) -e GID=$(id -g) -i wine-build bash <<EOF
set -exuo pipefail

OLDPWD=/wine-build
cd /wine-build

export USE_CCACHE=1
export CCACHE_DIR=/ccache
ccache --set-config=max_size=50.0G
ccache -s

mkdir -p wine64 wine32

cd wine64

/usr/src/wine/configure \\
  --exec-prefix="\${OLDPWD}/out" \\
  --prefix="\${OLDPWD}/out" \\
  --disable-win16 \\
  --enable-win64 \\
  --without-capi \\
  --without-cups \\
  --without-dbus \\
  --without-fontconfig \\
  --without-gettext \\
  --without-gphoto \\
  --without-gssapi \\
  --without-inotify \\
  --without-krb5 \\
  --without-netapi \\
  --without-opencl \\
  --without-osmesa \\
  --without-oss \\
  --without-pcap \\
  --without-pcsclite \\
  --without-capi \\
  --without-sane \\
  --without-sdl \\
  --without-udev \\
  --without-usb \\
  --without-v4l2 \\
  --with-x \\
  --without-xfixes \\
  --without-xinerama \\
  --without-xinput \\
  --without-xrandr \\
  --without-xxf86vm \\
  --without-xcursor \\
  --without-xinput2 \\
  LDFLAGS="-flto=auto" \\
  CFLAGS="-flto -ffat-lto-objects -pipe -fno-plt -fexceptions -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection" \\
  CC="ccache gcc" \\
  CXX="ccache g++" \\
  CROSSCC="ccache x86_64-w64-mingw32-gcc" \\
  CROSSXX="ccache x86_64-w64-mingw32-g++" \\
  PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu

make -j\$(nproc)
make install

cd "\${OLDPWD}"
cd wine32

/usr/src/wine/configure \\
  --exec-prefix="\${OLDPWD}/out" \\
  --prefix="\${OLDPWD}/out" \\
  --with-wine64="\${OLDPWD}/wine64" \\
  --disable-win16 \\
  --without-capi \\
  --without-cups \\
  --without-dbus \\
  --without-fontconfig \\
  --without-gettext \\
  --without-gphoto \\
  --without-gssapi \\
  --without-inotify \\
  --without-krb5 \\
  --without-netapi \\
  --without-opencl \\
  --without-osmesa \\
  --without-oss \\
  --without-pcap \\
  --without-pcsclite \\
  --without-capi \\
  --without-sane \\
  --without-sdl \\
  --without-udev \\
  --without-usb \\
  --without-v4l2 \\
  --with-x \\
  --without-xfixes \\
  --without-xinerama \\
  --without-xinput \\
  --without-xrandr \\
  --without-xxf86vm \\
  --without-xcursor \\
  --without-xinput2 \\
  LDFLAGS="-flto=auto" \\
  CFLAGS="-m32 -flto -ffat-lto-objects -pipe -fno-plt -fexceptions -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection" \\
  CC="ccache gcc" \\
  CXX="ccache g++" \\
  CROSSCC="ccache i686-w64-mingw32-gcc" \\
  CROSSXX="ccache i686-w64-mingw32-g++" \\
  PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

make -j\$(nproc)
make install

rm -rf "\${OLDPWD}/out/share/man" "\${OLDPWD}/out/share/applications" "\${OLDPWD}/out/include"

chown -R \${ID}:\${GID} "\${OLDPWD}/out"

EOF
