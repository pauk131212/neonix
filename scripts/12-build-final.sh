#!/bin/bash
# Финальная сборка: снять монтирования -> mksquashfs -> xorriso.
set -u
P=${P:-/home/builder/cubic-project}
S=$P/custom-root
D=$P/custom-disk
T=$D/casper/minimal.squashfs
VER=${VER:-1.1}
ISO=$P/neonix-personal-$VER-amd64.iso
echo builder | sudo -S -v 2>/dev/null

echo "== снимаем монтирования custom-root =="
for i in 1 2 3 4 5; do
    mount | grep -q custom-root || break
    sudo umount -l "$S/proc" 2>/dev/null
    sudo umount -l "$S/sys" 2>/dev/null
    sudo umount -l "$S/dev" 2>/dev/null
    sleep 1
done
mount | grep custom-root || echo "монтирований нет"

echo "== mksquashfs $(date) =="
sudo mksquashfs "$S" "$T" -noappend -comp zstd -wildcards \
    -e "proc/*" -e "proc/.*" -e "run/*" -e "run/.*" \
    -e "tmp/*" -e "tmp/.*" -e "var/crash/*" -e "var/crash/.*" \
    -e "swapfile" -e "root/.bash_history" -e "root/.cache" -e "root/.wget-hsts" \
    -e "home/*/.bash_history" -e "home/*/.cache" -e "home/*/.wget-hsts" \
    >/tmp/mksquashfs.log 2>&1
rc=$?
tail -4 /tmp/mksquashfs.log
echo "MKSQUASHFS_EXIT=$rc"
[ "$rc" -eq 0 ] || { echo "SQUASH FAILED"; exit 1; }
ls -l "$T"

echo "== xorriso $(date) =="
cd "$D" || exit 1
xorriso -as mkisofs -r -J -joliet-long -l -iso-level 3 \
  -m "$D/casper/install-sources.yaml.original" \
  -V "Neonix $VER" \
  --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:"$P/partition-1.img" \
  --protective-msdos-label \
  -partition_cyl_align off \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:0d-10159d::"$P/partition-2.img" \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot -e '--interval:appended_partition_2:all::' -no-emul-boot -boot-load-size 10160 \
  -o "$ISO" . >/tmp/xorriso.log 2>&1
rc=$?
tail -6 /tmp/xorriso.log
echo "XORRISO_EXIT=$rc"
[ "$rc" -eq 0 ] || { echo "ISO FAILED"; exit 1; }
ls -l "$ISO"

echo "== хеш ISO $(date) =="
sha256sum "$ISO"
echo DONE
