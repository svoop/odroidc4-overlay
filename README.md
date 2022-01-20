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
