#!/bin/bash
# Копирует тему plymouth neonix в chroot и патчит initrd (драйверы DRM + тема внутрь initrd).
set -u
SRC=${SRC:-/media/sf_work/neonix}
P=${P:-/home/builder/cubic-project/custom-root}
THEME=$SRC/branding/neonix/plymouth/neonix
T=$P/usr/share/plymouth/themes/neonix

echo builder | sudo -S -v 2>/dev/null

echo "== чистим старые ассеты темы =="
sudo rm -f "$T"/*.png "$T"/*.script "$T"/*.plymouth
sudo mkdir -p "$T"

echo "== копируем тему =="
sudo cp "$THEME/neonix.script" "$THEME/neonix.plymouth" "$T/"
sudo cp "$THEME"/assets/*.png "$T/"
sudo chmod 644 "$T"/*
echo "файлов в теме: $(ls "$T" | wc -l)"
echo "строк лога: $(ls "$T"/line_*.png | wc -l)"

echo "== plymouthd.conf =="
cat "$P/etc/plymouth/plymouthd.conf"

echo "== патч initrd =="
bash "$SRC/scripts/11-patch-initrd.sh"
echo DONE
