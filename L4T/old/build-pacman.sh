#!/bin/bash

set -e

BUILDDIR=/dev/shm
PACMANVER=5.1.3

sudo apt update
sudo apt install -y curl libssl-dev libcurl4-openssl-dev libarchive-dev bsdtar libgpgme-dev fakeroot fakechroot m4 autoconf

cd $BUILDDIR
if [ ! -f pacman-$PACMANVER.tar.gz ]; then
    wget https://sources.archlinux.org/other/pacman/pacman-$PACMANVER.tar.gz
fi
tar -xf pacman-$PACMANVER.tar.gz
cd pacman-$PACMANVER

./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --disable-doc \
    --with-pkg-ext='.pkg.tar.gz' \
    --with-src-ext='.src.tar.gz' \
    --with-scriptlet-shell=/bin/bash \
    --with-ldconfig=/sbin/ldconfig

make -j $(nproc)
# make check || :
sudo make install

sudo sed \
        -e '/CHOST=/s/aarch64-unknown-linux-gnu/aarch64-linux-gnu/' \
        -e '/CPPFLAGS=/s/^#//' \
        -e '/CPPFLAGS=/s/"\(.*\)"/"-D_FORTIFY_SOURCE=2"/' \
        -e '/CFLAGS=/s/^#//' \
        -e '/CFLAGS=/s/"\(.*\)"/"-O2 -pipe -fno-plt"/' \
        -e '/CXXFLAGS=/s/^#//' \
        -e '/CXXFLAGS=/s/"\(.*\)"/"-O2 -pipe -fno-plt"/' \
        -e '/LDFLAGS=/s/^#//' \
        -e '/LDFLAGS=/s/"\(.*\)"/"-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"/' \
        -e '/RUSTFLAGS=/s/^#//' \
        -e '/RUSTFLAGS=/s/"\(.*\)"/"-C opt-level=2"/' \
        -e '/MAKEFLAGS=/s/^#//' \
        -e '/MAKEFLAGS=/s/"\(.*\)"/"-j$(nproc)"/' \
        -e '/DEBUG_CFLAGS=/s/^#//' \
        -e '/DEBUG_CFLAGS=/s/"\(.*\)"/"-g -fvar-tracking-assignments"/' \
        -e '/DEBUG_CXXFLAGS=/s/^#//' \
        -e '/DEBUG_CXXFLAGS=/s/"\(.*\)"/"-g -fvar-tracking-assignments"/' \
        -e '/DEBUG_RUSTFLAGS=/s/"\(.*\)"/"-C debuginfo=2"/' \
        -e '/BUILDDIR=\/tmp\/makepkg/s/^#//' \
        -e '/BUILDDIR=\/tmp\/makepkg/s/tmp/dev\/shm/' \
        -e '/PKGDEST=/s/^#//' \
        -e '/SRCDEST=/s/^#//' \
        -e '/SRCPKGDEST=/s/^#//' \
        -e '/LOGDEST=/s/^#//' \
        -e '/PACKAGER=/s/^#//' \
        -e '/INTEGRITY_CHECK=/s/md5/sha256/' \
        -e '/PKGDEST=/s/\/home/~\/makepkg/' \
        -e '/SRCDEST=/s/\/home/~\/makepkg/' \
        -e '/SRCPKGDEST=/s/\/home/~\/makepkg/' \
        -e '/LOGDEST=/s/\/home/~\/makepkg/' \
        -e '/PACKAGER=/s/John Doe <john@doe.com>/Zelun Kong <zelun.kong@outlook.com>/' \
        -i /etc/makepkg.conf

sudo tee -a /etc/pacman.conf << EOF

[tegra]
SigLevel = Optional TrustAll
Server = file:///home/.repository/\$repo
EOF

sudo ldconfig