#!/bin/bash
eval $(/usr/bin/gnome-keyring-daemon --start --components=secrets,pkcs11,ssh)
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID SSH_AUTH_SOCK
dbus-update-activation-environment --all
