ODROID C4 Gentoo Overlay
========================

This overlay includes ebuilds for the following packages:

* `sys-kernel/odroidc4-sources`: Linux source for ODROID devices by @tobetter (https://github.com/tobetter/linux)


Usage with Layman
-----------------

```
emerge -av layman dev-vcs/git
mkdir /etc/portage/repos.conf
layman-updater -R
pico /etc/layman/layman.cfg
|   overlays  :
|       https://api.gentoo.org/overlays/repositories.xml
| +     https://github.com/svoop/odroidc4-overlay/raw/main/repositories.xml
layman -S
layman -a odroidc4
```
