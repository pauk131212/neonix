#!/bin/bash
F=/home/builder/cubic-project/custom-disk/casper/initrd.gz
OUT=/media/sf_work/initrd3.txt
{
  echo "== trailer offsets =="
  LC_ALL=C grep -abo 'TRAILER!!!' "$F" | head -5
  echo "== trailer count =="
  LC_ALL=C grep -ao 'TRAILER!!!' "$F" | wc -l
  echo "== cpio list tail =="
  cpio -t < "$F" 2>&1 | tail -3
  echo "== cpio entry count =="
  cpio -t < "$F" 2>&1 | wc -l
  echo "== plymouth entries =="
  cpio -t < "$F" 2>&1 | grep -i plymouth | head -20
} > "$OUT" 2>&1
echo DONE
