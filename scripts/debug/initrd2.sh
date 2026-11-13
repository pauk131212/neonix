#!/bin/bash
F=/home/builder/cubic-project/custom-disk/casper/initrd.gz
OUT=/media/sf_work/initrd2.txt
pkill -f lsinitramfs 2>/dev/null
{
  echo "== trailer occurrences =="
  LC_ALL=C grep -abo 'TRAILER!!!' "$F" | head -5
  echo "== trailer count =="
  LC_ALL=C grep -ao 'TRAILER!!!' "$F" | wc -l
  echo "== cpio list tail =="
  cpio -t < "$F" 2>&1 | tail -5
  echo "== cpio entry count =="
  cpio -t < "$F" 2>&1 | wc -l
  echo "== plymouth entries =="
  cpio -t < "$F" 2>&1 | grep -i plymouth | head -30
} > "$OUT" 2>&1
echo DONE
