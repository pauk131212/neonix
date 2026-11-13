#!/bin/bash
# Rebuild the Neonix ISO with the exact xorriso command Cubic uses.
# Needed because the first run truncated minimal.standard.live.squashfs.
cd /home/builder/cubic-project/custom-disk || exit 1

echo "START $(date)"
stat -c 'live squashfs: %s bytes, mtime %y' casper/minimal.standard.live.squashfs
df -h / | tail -1

xorriso -as mkisofs -r -J -joliet-long -l -iso-level 3 \
  -m "/home/builder/cubic-project/custom-disk/casper/install-sources.yaml.original" \
  -V 'Ubuntu 24.04.5 2026.11.09 LTS' \
  --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'/home/builder/cubic-project/partition-1.img' \
  --protective-msdos-label \
  -partition_cyl_align off \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:0d-10159d::'/home/builder/cubic-project/partition-2.img' \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot -e '--interval:appended_partition_2:all::' -no-emul-boot -boot-load-size 10160 \
  -o "/home/builder/cubic-project/ubuntu-24.04.5-2026.11.09.1-desktop-amd64.iso" .

echo "EXIT=$?"
echo "END $(date)"
df -h / | tail -1
stat -c 'iso: %s bytes' "/home/builder/cubic-project/ubuntu-24.04.5-2026.11.09.1-desktop-amd64.iso"
