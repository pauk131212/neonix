#!/bin/bash
P=/home/builder/cubic-project
F=$P/custom-disk/casper/initrd.gz
OUT=/media/sf_work/initrd-info.txt
{
  echo "== first bytes =="
  xxd -l 64 "$F"
  echo "== lsinitramfs count =="
  lsinitramfs "$F" 2>&1 | wc -l
  echo "== lsinitramfs head =="
  lsinitramfs "$F" 2>&1 | head -20
  echo "== plymouth entries =="
  lsinitramfs "$F" 2>&1 | grep -i plymouth | head -40
  echo "== gzip magic offsets =="
  LC_ALL=C grep -abo $'\x1f\x8b\x08' "$F" | head -3
  echo "== zstd magic offsets =="
  LC_ALL=C grep -abo $'\x28\xb5\x2f\xfd' "$F" | head -3
  echo "== xz magic offsets =="
  LC_ALL=C grep -abo $'\xfd7zXZ' "$F" | head -3
} > "$OUT" 2>&1
echo DONE
