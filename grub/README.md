# GRUB theme: minegrub

Copied from https://github.com/Lxtharia/minegrub-theme (MIT, see
LICENSE-minegrub), commit cdd067ebc31ac59e24ae3c99e5b0f05a18eb8a1d, so a fresh install needs no download.
Only the `minegrub/` theme folder is kept: without the boot-time updater
(`update_theme.py`, a root service that rewrites the theme in /boot), its
fonts and the extra backgrounds. The splash text on the logo is therefore
fixed; install/lib.sh (do_grub_theme) fills in the real package count.

Re-install / update: `install/grub.sh`
