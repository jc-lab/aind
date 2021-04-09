#!/bin/bash
# docker-2ndboot.sh is executed as a non-root user via `unsudo`.

function finish {
    set +x
    figlet ERROR
    : FIXME: the container should shutdown automatically here
}
trap finish EXIT

cd $(realpath $(dirname $0)/..)
set -eux

export DISPLAY=:0
export EGL_PLATFORM=x11

if ! systemctl is-system-running --wait; then
    systemctl status --no-pager -l anbox-container-manager
    journalctl -u anbox-container-manager --no-pager -l
    exit 1
fi
systemctl status --no-pager -l anbox-container-manager

xpra start --exec-wrapper="/usr/bin/vglrun" --start="anbox session-manager" --bind-tcp=0.0.0.0:14500 &

until anbox wait-ready; do sleep 1; done
anbox launch --package=org.anbox.appmgr --component=org.anbox.appmgr.AppViewActivity

adb wait-for-device

# install apk (pre-installed apps such as F-Droid)
for f in /apk-pre.d/*.apk; do adb install $f; done

# install apk
if ls /apk.d/*.apk; then
    for f in /apk.d/*.apk; do adb install $f; done
fi

# done
figlet "Ready"
echo "Hint: the password is stored in $HOME/.vnc/passwdfile"
exec sleep infinity
