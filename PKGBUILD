# Maintainer: Evine Deng <evinedeng@hotmail.com>

_pkgname=r8125
pkgname="${_pkgname}-dkms"
pkgver=9.018.00
pkgrel=1
priority=optional
section=non-free/kernel
url="https://www.realtek.com/Download/List?cate_id=584"
pkgdesc="dkms source for the r8125 network driver"
license=('GPL-2.0-only')
arch=('all')
depends=('dkms')
provides=("${pkgname}")
conflicts=("${pkgname}" "realtek-${pkgname}")
replaces=("realtek-${pkgname}")
postinst="postinst.sh"
prerm="prerm.sh"
optdepends=('s!linux-headers-amd64: Build the module for Debian kernel'
            's!proxmox-default-headers: Build the module for Proxmox VE kernel')
source=("${_pkgname}-${pkgver}.tar.bz2::https://github.com/devome/${pkgname}/releases/download/${pkgver}-${pkgrel}/${_pkgname}-${pkgver}.tar.bz2"
        "dkms.conf")
sha256sums=('66291cb5d4d3b359cfa0c9ca902028d9ce0f76065887cb64b4052dce4a676ff8'
            'afb4b4a62803309448ea698fb316d405337866ae3d7206ce52e9470c07c4a634')

prepare() {
    cd "${_pkgname}-${pkgver}"
    rm src/Makefile_linux24x
    sed -e "s|@PKGVER@|${pkgver}|g" ../dkms.conf > src/dkms.conf
}

package() {
    cd "${_pkgname}-${pkgver}"
    install -Dm644 -t "${pkgdir}/usr/share/doc/${pkgname}"      README
    install -Dm644 -t "${pkgdir}/usr/src/${_pkgname}-${pkgver}" src/*
}
