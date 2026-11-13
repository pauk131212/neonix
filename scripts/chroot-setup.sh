#!/bin/bash
# Neonix: configure the Cubic chroot in one pass.
# Run inside the Cubic terminal as root:
#   bash /mnt/w/build/chroot-setup.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

SRC=/mnt/w/build

echo "==> [1/7] apt update"
apt update

echo "==> [2/7] ensure universe"
add-apt-repository -y universe >/dev/null 2>&1 || true
apt update

echo "==> [3/7] XFCE + applications"
# firefox is already on the ISO as a snap; skip the transitional deb.
grep -v '^#' "$SRC/packages-xfce.txt" | sed '/^[[:space:]]*$/d' | grep -v '^firefox$' \
  | xargs apt install -y --no-install-recommends

echo "==> [4/7] default session: XFCE"
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
ln -sf /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
systemctl enable lightdm.service >/dev/null 2>&1 || true
systemctl disable gdm3.service >/dev/null 2>&1 || true

mkdir -p /home/ubuntu /etc/skel
printf '[Desktop]\nSession=xfce\n' > /home/ubuntu/.dmrc
printf '[Desktop]\nSession=xfce\n' > /etc/skel/.dmrc
chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true

mkdir -p /var/lib/AccountsService/users
cat > /var/lib/AccountsService/users/ubuntu <<'EOF'
[User]
Language=ru_RU.UTF-8
XSession=xfce
SystemAccount=false
EOF

echo "==> [5/7] Russian locale"
locale-gen ru_RU.UTF-8
update-locale LANG=ru_RU.UTF-8

echo "==> [6/7] Neonix branding"
bash "$SRC/neonix/apply-branding.sh" "$SRC/neonix"

echo "==> [7/7] cleanup"
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true

echo
echo "==> DONE. Neonix chroot is ready."
