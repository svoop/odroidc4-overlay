Installing Gentoo Linux on an ODROID C4
=======================================

This is an optionated install log for an ODROID C4 with RTC shield. You might want to tweak it to fit your needs.

Please let me know if there's anything important missing or wrong.

```
# Official Hardkernel Ubuntu is using kernel 4.9 which breaks btrfs on ARM.
# Use the latest unofficial Ubuntu image (at least 5.4) by @tobetter.
# https://docs.linuxfactory.or.kr/install/odroidc4/image.html

sudo su -

parted /dev/mmcblk1
| mklabel msdos
| mkpart p ext4 10M 210M
| mkpart p btrfs 210M 100%
| toggle 1 boot
| quit

apt update
apt install btrfs-progs nano

mkfs.ext4 -L boot /dev/mmcblk1p1
mkfs.btrfs -L root /dev/mmcblk1p2
mkdir /mnt/root
mount /dev/mmcblk1p2 /mnt/root
btrfs sub create /mnt/root/@
btrfs sub create /mnt/root/@swap
umount /mnt/root
mount -o subvol=@,noatime,compress=lzo,autodefrag /dev/mmcblk1p2 /mnt/root
mkdir /mnt/root/swap
mount -o subvol=@swap,noatime /dev/mmcblk1p2 /mnt/root/swap
touch /mnt/root/swap/swapfile
chmod 600 /mnt/root/swap/swapfile
chattr +C /mnt/root/swap/swapfile
fallocate /mnt/root/swap/swapfile -l6g
mkswap /mnt/root/swap/swapfile
swapon /mnt/root/swap/swapfile

# Find the newest stage 3 on:
# http://ftp.free.fr/mirrors/ftp.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64/

TIMESTAMP="20210318T005104Z"
STAGE3="stage3-arm64-$TIMESTAMP"
wget http://ftp.free.fr/mirrors/ftp.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64/$STAGE3.tar.xz
tar xJf $STAGE3.tar.xz -C /mnt/root/

nano /mnt/root/etc/portage/make.conf
| COMMON_FLAGS="-O2 -pipe -mcpu=cortex-a55 -mabi=lp64 -ftree-vectorize --param l1-cache-size=32 --param l1-cache-line-size=32 --param l2-cache-size=512"
| CFLAGS="${COMMON_FLAGS}"
| CXXFLAGS="${COMMON_FLAGS}"
| FCFLAGS="${COMMON_FLAGS}"
| FFLAGS="${COMMON_FLAGS}"
| CHOST="aarch64-unknown-linux-gnu"
| LDFLAGS="-Wl,-O1 -Wl,--as-needed"
| MAKEOPTS="-j4"
| CPU_FLAGS_ARM="edsp neon thumb vfp vfpv3 vfpv4 vfp-d32 crc32 v4 v5 v6 v7 v8 thumb2"
| AUTOCLEAN="yes"
| EMERGE_DEFAULT_OPTS="--with-bdeps=y --quiet-build=y"
|
| PORTAGE_COMPRESS="bzip2"
| PORTAGE_COMPRESS_FLAGS="-9"
|
| ACCEPT_LICENSE="* -@EULA"
| LINGUAS="en"
| L10N="en"
| USE="logrotate symlink"

cp -L /etc/resolv.conf /mnt/root/etc/
mount -t proc proc /mnt/root/proc
mount --rbind /sys /mnt/root/sys
mount --make-rslave /mnt/root/sys
mount --rbind /dev /mnt/root/dev
mount --make-rslave /mnt/root/dev

chroot /mnt/root /bin/bash
source /etc/profile
mount /dev/mmcblk1p1 /boot

emerge --sync
mkdir /etc/portage/package.accept_keywords

echo "app-editors/joe **" >/etc/portage/package.accept_keywords/joe   # Not yet available for arm64
emerge -av app-editors/joe
nano -w /etc/bash/bashrc.d/joe
| export EDITOR=jpico
| alias pico=jpico
| alias edit=jpico
source /etc/bash/bashrc

passwd
groupadd ssh-users
useradd -c "John Doe" -m -G users,ssh-users jdoe    # Copy the SSH keys once the users are created
passwd jdoe
pico /etc/ssh/sshd_config
| - #HostKey /etc/ssh/ssh_host_ed25519_key
| + HostKey /etc/ssh/ssh_host_ed25519_key
|
| - #PermitRootLogin prohibit-password
| + PermitRootLogin no
|
| - #PasswordAuthentication yes
| + PasswordAuthentication no
|
| - #ChallengeResponseAuthentication yes
| + ChallengeResponseAuthentication no
|
| - UsePAM yes
| + UsePAM no
|
| - #TCPKeepAlive yes
| + TCPKeepAlive yes
|
| - #ClientAliveInterval 0
| - #ClientAliveCountMax 3
| + ClientAliveInterval 120
| + ClientAliveCountMax 30
|
| + AllowGroups ssh-users
| + KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
| + Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
| + MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
rc-update add sshd default

pico /etc/locale.gen
| + en_US.UTF-8 UTF-8
| + en_US ISO-8859-15
|   #ja_JP.EUC-JP EUC-JP
locale-gen
pico /etc/env.d/02locale
| LANG="en_US.utf8"
cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
pico /etc/timezone
| Europe/Berlin

emerge -av app-eselect/eselect-repository
eselect repository add odroidc4 git https://github.com/svoop/odroidc4-overlay
emerge --sync

emerge -av sys-fs/btrfs-progs
blkid   # Get ROOT_UUID and BOOT_UUID
pico /etc/fstab   # Must not have an empty line at the end
| UUID={ROOT_UUID} / btrfs defaults,subvol=@,noatime,compress=lzo,autodefrag 0 1
| UUID={ROOT_UUID} /swap btrfs defaults,subvol=@swap,noatime 0 0
| /swap/swapfile none swap sw 0 0
| UUID={BOOT_UUID} /boot ext4 defaults,noatime 0 2

pico /boot/boot.ini
| ODROIDC4-UBOOT-CONFIG
|
| setenv bootlabel "Gentoo Linux"
| setenv fk_kvers "5.11.9"
| setenv fdtfile "meson64_odroidc4.dtb"
|
| setenv root_uuid "{ROOT_UUID}"
| setenv root_flags "defaults,subvol=@,noatime,compress=lzo,autodefrag"
| setenv bootargs " ${bootargs} root=UUID=${root_uuid} rootflags=${root_flags}"
| setenv overlays "pcf8563 spi0"
|
| setenv bootargs "${bootargs} console=tty1 cma=800M clk_ignore_unused"
| setenv bootargs "${bootargs} console=ttyAML0,115200n8"
|
| setenv fdt_addr_r "0x20000000"
| setenv dtbo_addr_r 0x21000000
| setenv zimage_addr_r ${ramdisk_addr_r}
|
| load ${devtype} ${devnum}:${partition} ${fdt_addr_r} ${prefix}dtbs/${fk_kvers}/amlogic/${fdtfile}
| if test -n "${overlays}"; then
|   fdt addr ${fdt_addr_r}
|   fdt resize 16384
|   setenv overlay_path ${prefix}dtbs/${fk_kvers}/amlogic/overlays/odroid${variant}
|   for overlay in ${overlays}; do
|     load ${devtype} ${devnum}:${partition} ${dtbo_addr_r} ${overlay_path}/${overlay}.dtbo \
|       && fdt apply ${dtbo_addr_r}
|   done
| fi
|
| load ${devtype} ${devnum}:${partition} ${zimage_addr_r} ${prefix}vmlinuz-${fk_kvers} \
|   && unzip ${zimage_addr_r} ${kernel_addr_r} \
|   && load ${devtype} ${devnum}:${partition} ${fdt_addr_r} ${prefix}dtb-${fk_kvers} \
|   && load ${devtype} ${devnum}:${partition} ${ramdisk_addr_r} ${prefix}initramfs-${fk_kvers}.img \
|   && echo "Booting ${bootlabel} ${fk_kvers} from ${devtype} ${devnum}:${partition}..." \
|   && booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}

pico /etc/inittab
|   # Architecture specific features
| - f0:12345:respawn:/sbin/agetty 9600 ttyAMA0 vt100
| + f0:12345:respawn:/sbin/agetty 115200 ttyAML0 xterm-256color

emerge -av sys-apps/busybox
pico /etc/conf.d/hostname
| - hostname="localhost"
| + hostname="odroidc4"
pico /etc/conf.d/net
| config_eth0="dhcp"
ln -s net.lo /etc/init.d/net.eth0
rc-update add net.eth0 default
pico /etc/hosts
| - 127.0.0.1       localhost
| - ::1             localhost
| + 127.0.0.1       odroidc4.example.com odroidc4 localhost
| + ::1             odroidc4.exmaple.com odroidc4 localhost

pico /etc/sysctl.conf
| - #kernel.panic = 3
| + kernel.panic = 3

emerge -q --sync
emerge -a --update --deep --newuse @world
emerge -av @world
emerge -a --update --deep --newuse @world
dispatch-conf

emerge -av sys-kernel/dracut sys-apps/dtc

emerge -av sys-kernel/odroidc4-sources
echo "sys-kernel/odroidc4-sources" >/etc/portage/package.accept_keywords/odroidc4-sources
emerge -av odroidc4-sources
# Follow the instructions to get a vanilla .config and install the kernel

# Use the latest pre-compiled u-boot by Hardkernel.
# https://github.com/hardkernel/u-boot/releases

cd
RELEASE="189"
wget https://github.com/hardkernel/u-boot/releases/download/travis%2Fodroidc4-$RELEASE/u-boot-odroidc4-$RELEASE.tar.gz
tar xzf u-boot-odroidc4-*.tar.gz
mv sd_fuse/u-boot.bin /boot
chown root:root /boot/u-boot.bin
rm -rf sd_fuse u-boot-odroidc4-*
dd if=/boot/u-boot.bin of=/dev/mmcblk1 conv=fsync,notrunc bs=512 seek=1
sync

umount /boot
exit

swapoff /mnt/root/swap/swapfile
umount /mnt/root/swap
umount -l /mnt/root/dev{/shm,/pts,}
umount -R /mnt/root{/sys,/proc}
lsof | grep /mnt/root    # Check if anything is still busy on /mnt/root
umount /mnt/root

sync
shutdown -r now

emerge -av net-misc/ntp
rc-service ntp-client start
rc-service ntpd start
rc-update add ntpd
hwclock -w --utc

emerge -av app-portage/gentoolkit sys-apps/usbutils
```
