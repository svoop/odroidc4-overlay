# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Forked from sys-kernel/raspberrypi-sources

EAPI=6

ETYPE=sources
K_DEFCONFIG="odroidc4_defconfig"
K_SECURITY_UNSUPPORTED=1

inherit kernel-2 eapi7-ver
detect_version

MY_PV=$(ver_cut 1-2).0

DESCRIPTION="ODROID C4 kernel sources"
HOMEPAGE="https://github.com/tobetter/linux"
REF=36e79999c1966bbca0dbfa83171fa307441e8453
SRC_URI="https://github.com/tobetter/linux/archive/${REF}.tar.gz -> linux-${KV_FULL}.tar.gz"

KEYWORDS="~arm64"

src_unpack() {
	default
	mv "${WORKDIR}"/linux-${REF} "${WORKDIR}"/linux-${KV_FULL} || die
}

pkg_postinst() {
	deb_url="http://ppa.linuxfactory.or.kr/pool/main/l/linux/"
	deb_file=$(curl -s "${deb_url}" | grep "linux-image-${MY_PV}-odroid-arm64" | tail -n 1 | grep -Po 'linux-image.*?deb(?=")')
	elog "To get a working upstream kernel config as a starting point:"
	elog
	elog "mkdir /tmp/odroidc4"
	elog "wget -O /tmp/odroidc4/image.deb $deb_url$deb_file"
	elog "(cd /tmp/odroidc4 && ar x image.deb data.tar.xz && tar xJf data.tar.xz)"
	elog "cp /tmp/odroidc4/boot/config-* /usr/src/linux-${KV_FULL}/.config"
	elog "rm -rf /tmp/odroidc4"
	elog
	elog "To build and install this kernel:"
	elog
	elog "cd -P /usr/src/linux"
	elog "make oldconfig"
	elog "make && make modules_install"
	elog "make zinstall"
	elog "make dtbs_install"
	elog "dracut --force --kver ${PV}"
	elog "ln -fs initramfs-${PV}.img /boot/initramfs.img"
	elog "ln -fs dtbs/${PV}/amlogic/meson64_odroidc4.dtb /boot/dtb-${PV}"
	elog "ln -fs dtb-${PV} /boot/dtb"
}
