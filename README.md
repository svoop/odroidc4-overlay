ODROID-C4 Gentoo Overlay
========================

This overlay includes ebuilds to install Gentoo Linux on ODROID-C4 devices using [sources by @tobetter](https://github.com/tobetter/linux)

Add the Overlay
---------------

```
emerge --ask app-eselect/eselect-repository
eselect repository add odroidc4 git https://github.com/svoop/odroidc4-overlay
emerge --sync
```

Install Gentoo on an ODROID C4
------------------------------

See `INSTALL.md` for a "worked for me" install log on a virgin ODROID C4.

Feel free to fork and submit pull requests for fixes or enhancements.

Recover from Boot Failure
-------------------------

If a new kernel or config changes prevents the ODROID C4 from booting, hit `Ctrl-C` during boot and at the U-boot prompt enter:

```
setenv devtype "mmc"
setenv devnum 0
setenv partition 1
```

Then copy and paste [all commands from `boot.ini`](https://github.com/svoop/odroidc4-overlay/blob/main/INSTALL.md) using the previously working kernel version instead. You have to know the UUID of the root filesystem, otherwise, you'd have to guess the root filesystem device e.g. `/dev/mmcblk1p2`.

Update Kernel in Overlay
------------------------

The latest ODROID C4 compatible kernel version is [5.11.y from tobetter](https://github.com/tobetter/linux/tree/odroid-5.11.y). The commit used by any particular ebuild is set by `REF`. To find out the kernel version of any commit in the repository, check the [top lines of the root `Makefile`](https://github.com/tobetter/linux/blob/odroid-5.11.y/Makefile).
