#!/bin/bash
F=/home/builder/cubic-project/custom-disk/casper/initrd.gz
OUT=/media/sf_work/initrd6.txt
{
  for o in 0 305784 15106560 65747456; do
    echo "== offset $o =="
    xxd -s "$o" -l 16 "$F"
  done
  echo "== main tree =="
  find /tmp/initrd-x/main -type f | head -20
  echo "== extra tree (first 20) =="
  find /tmp/initrd-x/extra -type f | head -20
  echo "== extra size =="
  du -sh /tmp/initrd-x/extra
} > "$OUT" 2>&1
echo DONE
