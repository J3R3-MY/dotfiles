#!/usr/bin/env bash
# Sleep like a Mac: suspend now, hibernate after 12 h asleep or on low battery
# (suspend-then-hibernate, set up by install/hibernate.sh). Plain suspend if
# hibernation isn't available. The lock screen comes up through swayidle's
# before-sleep hook either way.
if busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager CanSuspendThenHibernate 2>/dev/null | grep -q '"yes"'; then
    exec systemctl suspend-then-hibernate
else
    exec systemctl suspend
fi
