#!/bin/bash
# Конфиги сессии (sway/waybar/Hyprland), запуск сессии, смена обоев, обои в системе.
set -u
SRC=${SRC:-/media/sf_work/neonix}
P=${P:-/home/builder/cubic-project/custom-root}
S=$SRC/session

echo builder | sudo -S -v 2>/dev/null

H="$P/home/ubuntu/.config"
sudo install -d "$H/sway" "$H/waybar"
sudo install -m 644 "$S/sway-config"       "$H/sway/config"
sudo install -m 644 "$S/waybar-sway.jsonc" "$H/waybar/config-sway.jsonc"
sudo install -m 755 "$S/neonix-session-start" "$P/usr/local/bin/neonix-session-start"
sudo install -m 755 "$S/neonix-wallpaper"     "$P/usr/local/bin/neonix-wallpaper"
sudo install -m 644 "$S/neonix-session.service" "$P/etc/systemd/system/neonix-session.service"

# обои (и тот же файл — фон меню GRUB)
sudo install -d "$P/usr/share/backgrounds/neonix"
sudo install -m 644 "$SRC/branding/neonix/assets/wallpaper.png" \
    "$P/usr/share/backgrounds/neonix/wallpaper.png"
if [ -d "$P/usr/share/grub/themes/neonix" ]; then
    sudo install -m 644 "$SRC/branding/neonix/assets/wallpaper.png" \
        "$P/usr/share/grub/themes/neonix/background.png"
fi

# копии для новых пользователей
sudo install -d "$P/etc/skel/.config/sway" "$P/etc/skel/.config/waybar"
sudo install -m 644 "$S/sway-config"       "$P/etc/skel/.config/sway/config"
sudo install -m 644 "$S/waybar-sway.jsonc" "$P/etc/skel/.config/waybar/config-sway.jsonc"

sudo chown -R 1000:1000 "$P/home/ubuntu/.config"

echo "== юнит сессии =="
sudo systemctl --root="$P" enable neonix-session.service 2>&1 | tail -2
ls -l "$P/etc/systemd/system/graphical.target.wants/" 2>/dev/null
echo "== обои =="
ls -l "$P/usr/share/backgrounds/neonix/wallpaper.png" "$P/usr/local/bin/neonix-wallpaper"
echo DONE
