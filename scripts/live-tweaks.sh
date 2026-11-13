#!/bin/bash
# Neonix live-session tweaks (run inside the Cubic chroot as root).
set -euo pipefail

echo "==> lightdm autologin for the live user"
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf <<'EOF'
[Seat:*]
autologin-user=ubuntu
autologin-user-timeout=0
autologin-session=xfce
EOF
cat /etc/lightdm/lightdm.conf.d/50-autologin.conf

echo "==> display-manager target"
ls -l /etc/systemd/system/display-manager.service || true

echo "==> DONE"
