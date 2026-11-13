#!/bin/bash
# Neonix branding installer.
# Run inside the Cubic chroot as root:
#   bash /media/sf_work/build/neonix/apply-branding.sh
#
# Optional argument: path to the branding source (default /media/sf_work/build/neonix).
set -euo pipefail

SRC="${1:-/media/sf_work/build/neonix}"
DISTRO="Neonix"
VERSION="1.0"

if [ ! -d "$SRC" ]; then
    echo "ERROR: branding source not found: $SRC" >&2
    exit 1
fi

echo "==> Plymouth theme"
install -d /usr/share/plymouth/themes/neonix
install -m 644 "$SRC"/plymouth/neonix/neonix.plymouth /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/plymouth/neonix/neonix.script   /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/assets/background.png /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/assets/logo.png       /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/assets/box_on.png     /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/assets/box_off.png    /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/assets/cursor.png     /usr/share/plymouth/themes/neonix/
install -m 644 "$SRC"/assets/anim/*.png     /usr/share/plymouth/themes/neonix/

# Fallback static theme (no animation)
install -d /usr/share/plymouth/themes/neonix-static
install -m 644 "$SRC"/plymouth/neonix-static/neonix-static.plymouth /usr/share/plymouth/themes/neonix-static/
install -m 644 "$SRC"/plymouth/neonix-static/neonix-static.script   /usr/share/plymouth/themes/neonix-static/
install -m 644 "$SRC"/assets/background.png /usr/share/plymouth/themes/neonix-static/
install -m 644 "$SRC"/assets/logo.png       /usr/share/plymouth/themes/neonix-static/
install -m 644 "$SRC"/assets/box_on.png     /usr/share/plymouth/themes/neonix-static/
install -m 644 "$SRC"/assets/box_off.png    /usr/share/plymouth/themes/neonix-static/
install -m 644 "$SRC"/assets/cursor.png     /usr/share/plymouth/themes/neonix-static/

# Ubuntu 24.04 no longer ships plymouth-set-default-theme, so fall back
# to writing /etc/plymouth/plymouthd.conf directly.
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme -R neonix
else
    install -d /etc/plymouth
    cat > /etc/plymouth/plymouthd.conf <<EOF
[Daemon]
Theme=neonix
ShowDelay=0
DeviceTimeout=8
EOF
    # The initramfs hook reads the default.plymouth alternative, not
    # plymouthd.conf, so register the theme there as well.
    update-alternatives --install \
        /usr/share/plymouth/themes/default.plymouth default.plymouth \
        /usr/share/plymouth/themes/neonix/neonix.plymouth 200 2>/dev/null || true
    update-alternatives --set default.plymouth \
        /usr/share/plymouth/themes/neonix/neonix.plymouth 2>/dev/null || true
    update-initramfs -u || true
fi

echo "==> Wallpaper"
install -d /usr/share/backgrounds/neonix
install -m 644 "$SRC"/assets/wallpaper.png /usr/share/backgrounds/neonix/wallpaper.png

echo "==> os-release"
cat > /usr/lib/os-release <<EOF
PRETTY_NAME="$DISTRO $VERSION"
NAME="$DISTRO"
VERSION_ID="$VERSION"
VERSION="$VERSION (Noble)"
VERSION_CODENAME=noble
ID=neonix
ID_LIKE=ubuntu
HOME_URL="https://example.org/"
SUPPORT_URL="https://example.org/support"
BUG_REPORT_URL="https://example.org/bugs"
PRIVACY_POLICY_URL="https://example.org/privacy"
UBUNTU_CODENAME=noble
LOGO=neonix-logo
EOF

if [ ! -L /etc/os-release ]; then
    rm -f /etc/os-release
    ln -s ../usr/lib/os-release /etc/os-release
fi

cat > /etc/lsb-release <<EOF
DISTRIB_ID=$DISTRO
DISTRIB_RELEASE=$VERSION
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="$DISTRO $VERSION"
EOF

printf '%s %s \\n \\l\n' "$DISTRO" "$VERSION" > /etc/issue
printf '%s %s\n' "$DISTRO" "$VERSION" > /etc/issue.net

echo "==> LightDM greeter"
install -d /etc/lightdm
install -m 644 "$SRC"/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
if [ -x /usr/sbin/lightdm ]; then
    echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
fi

echo "==> XFCE defaults for new users"
install -d /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
install -m 644 "$SRC"/xfce/xfce4-desktop.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
install -m 644 "$SRC"/xfce/xsettings.xml    /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
install -d /etc/skel/.config/xfce4/terminal
install -m 644 "$SRC"/xfce/terminalrc /etc/skel/.config/xfce4/terminal/terminalrc
install -m 644 "$SRC"/skel/.dmrc /etc/skel/.dmrc

echo "==> XFCE session defaults (wallpaper + dark theme)"
# The live user's home already exists in the squashfs, so casper does not
# copy /etc/skel. This autostart entry applies the wallpaper and the dark
# theme for every user, including the live session.
install -d /usr/local/bin
install -m 755 "$SRC"/xfce/neonix-session /usr/local/bin/neonix-session
install -d /etc/xdg/autostart
install -m 644 "$SRC"/xfce/neonix-session.desktop /etc/xdg/autostart/neonix-session.desktop

echo "==> Live user (casper)"
if id ubuntu >/dev/null 2>&1; then
    cp -an /etc/skel/. /home/ubuntu/ 2>/dev/null || true
    printf '[Desktop]\nSession=xfce\n' > /home/ubuntu/.dmrc
    chown -R ubuntu:ubuntu /home/ubuntu 2>/dev/null || true
fi

echo "==> GRUB theme"
if [ -d /usr/share/grub ]; then
    install -d /usr/share/grub/themes/neonix
    install -m 644 "$SRC"/grub/theme.txt /usr/share/grub/themes/neonix/theme.txt
    install -m 644 "$SRC"/assets/wallpaper.png /usr/share/grub/themes/neonix/background.png
    if [ -f /etc/default/grub ]; then
        sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="'"$DISTRO"'"|' /etc/default/grub
        if grep -q '^GRUB_THEME=' /etc/default/grub; then
            sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/neonix/theme.txt"|' /etc/default/grub
        else
            echo 'GRUB_THEME="/usr/share/grub/themes/neonix/theme.txt"' >> /etc/default/grub
        fi
        update-grub || true
    fi
fi

echo "==> Done. Branding applied."
echo "    Verify: cat /etc/os-release && ls /usr/share/plymouth/themes/neonix"
