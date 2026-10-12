#!/usr/bin/env bash
# SSH into this laptop: off by default (install/lib.sh masks sshd).
#
#   fluid-ssh.sh on       start sshd + open the firewall until the next reboot
#   fluid-ssh.sh off      stop it, mask it, close the firewall again
#   fluid-ssh.sh status
#
# Logins are key-only (~/.ssh/authorized_keys), no root, only you
# (/etc/ssh/sshd_config.d/10-fluid.conf).
set -u
case "${1:-status}" in
    on)
        [ -s "$HOME/.ssh/authorized_keys" ] || echo "note: ~/.ssh/authorized_keys is empty, nobody can log in yet" >&2
        sudo systemctl unmask sshd.service && sudo systemctl start sshd.service \
            && sudo firewall-cmd -q --add-service=ssh \
            && echo "SSH on until reboot (or fluid-ssh.sh off)" ;;
    off)
        sudo firewall-cmd -q --remove-service=ssh 2>/dev/null
        sudo systemctl stop sshd.service; sudo systemctl mask sshd.service >/dev/null 2>&1
        echo "SSH off" ;;
    status)
        echo "sshd: $(systemctl is-active sshd.service) ($(systemctl is-enabled sshd.service 2>/dev/null))"
        ss -ltnH 'sport = :22' | grep -q . && echo "port 22: listening" || echo "port 22: closed" ;;
    *) echo "usage: fluid-ssh.sh on|off|status" >&2; exit 2 ;;
esac
