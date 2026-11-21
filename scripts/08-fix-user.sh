#!/bin/bash
# Создаёт пользователя ubuntu в chroot.
# ВАЖНО: базовый live-server ISO не создаёт пользователя, а юнит сессии ждёт User=ubuntu.
# Без этого — чёрный экран и «Login incorrect» на tty.
set -u
P=${P:-/home/builder/cubic-project/custom-root}

echo "== пользователь ubuntu =="
sudo chroot "$P" /bin/bash -c '
set -e
getent group ubuntu >/dev/null || groupadd -g 1000 ubuntu
getent passwd ubuntu >/dev/null || useradd -u 1000 -g 1000 -m -s /bin/bash \
    -G adm,sudo,audio,video,render,input,plugdev,netdev,cdrom,users ubuntu
passwd -d ubuntu
'
echo "== проверка =="
sudo grep '^ubuntu:' "$P/etc/passwd"
sudo grep '^ubuntu:' "$P/etc/group"
echo DONE
