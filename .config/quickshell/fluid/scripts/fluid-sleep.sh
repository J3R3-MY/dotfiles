#!/usr/bin/env bash
# Hibernate if the system can (swap big enough, resume set up — see
# install/hibernate.sh), otherwise suspend. The lock screen comes up through
# swayidle's before-sleep hook either way.
if busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager CanHibernate 2>/dev/null | grep -q '"yes"'; then
    exec systemctl hibernate
else
    exec systemctl suspend
fi
