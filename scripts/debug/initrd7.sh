#!/bin/bash
set -e
F=/home/builder/cubic-project/custom-disk/casper/initrd.gz
W=/tmp/initrd-x
OUT=/media/sf_work/initrd7.txt
rm -rf "$W/root"
mkdir -p "$W/root"
tail -c +65747457 "$F" | zstd -d -c | ( cd "$W/root" && cpio -idm --quiet )
{
  echo "== root top =="
  ls "$W/root"
  echo "== plymouth plugin dir =="
  ls -la "$W/root/usr/lib/x86_64-linux-gnu/plymouth" 2>&1 | head -20
  echo "== themes =="
  ls -la "$W/root/usr/share/plymouth/themes" 2>&1
  echo "== default.plymouth =="
  ls -la "$W/root/usr/share/plymouth/themes/default.plymouth" 2>&1
  echo "== plymouthd.conf =="
  cat "$W/root/etc/plymouth/plymouthd.conf" 2>&1
  echo "== plymouth binary =="
  ls -la "$W/root/usr/bin/plymouthd" "$W/root/usr/sbin/plymouthd" 2>&1
  echo "== file count =="
  find "$W/root" -type f | wc -l
} > "$OUT" 2>&1
echo DONE
