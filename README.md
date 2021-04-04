ODROID C4 Gentoo Overlay
========================

This overlay includes ebuilds for the following packages:

* `sys-kernel/odroidc4-sources`: Linux source for ODROID devices by @tobetter (https://github.com/tobetter/linux)

See INSTALL.md for how to install Gentoo on a virgin ODROID C4.


Usage with Layman
-----------------

```
mkdir -p /etc/portage/package.use
echo "app-portage/layman sync-plugin-portage" > /etc/portage/package.use/layman
emerge -av dev-util/git app-portage/layman

pico /etc/layman/layman.cfg
|   overlays  :
|       https://api.gentoo.org/overlays/repositories.xml
| +     https://github.com/svoop/odroidc4-overlay/raw/main/repositories.xml
layman -S
layman -a odroidc4
```
