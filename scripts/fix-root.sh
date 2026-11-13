#!/bin/bash
set -e
P=/home/builder/cubic-project
R=$P/custom-root
D=$P/custom-disk
B=/media/sf_work/build

install -m 755 "$B/neonix-session" "$R/usr/local/bin/neonix-session"
install -m 644 "$B/neonix-session.desktop" "$R/etc/xdg/autostart/neonix-session.desktop"

sed -i 's/Try or Install Ubuntu/Try or Install Neonix/g; s/Ubuntu (safe graphics)/Neonix (safe graphics)/g' \
    "$D/boot/grub/grub.cfg" "$D/boot/grub/loopback.cfg"

{
    echo "== grub menu =="
    grep -n menuentry "$D/boot/grub/grub.cfg"
    echo "== loopback menu =="
    grep -n menuentry "$D/boot/grub/loopback.cfg"
    echo "== installed files =="
    ls -l "$R/usr/local/bin/neonix-session" "$R/etc/xdg/autostart/neonix-session.desktop"
    echo "== initrd =="
    stat -c 'size %s bytes' "$D/casper/initrd.gz"
    tail -c +65747457 "$D/casper/initrd.gz" | zstd -d -c 2>/dev/null | cpio -t 2>/dev/null | grep -E 'themes/neonix/(neonix\.plymouth|neonix\.script|bg\.png)|plymouth/script\.so|plymouthd\.conf' | head
    echo "== install-sources =="
    cat "$D/casper/install-sources.yaml"
} > /media/sf_work/fix-root.txt 2>&1
echo DONE
