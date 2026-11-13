#!/bin/bash
P=/home/builder/cubic-project
OUT=/media/sf_work/layers.txt
{
  echo "== live layer (minimal.standard.live.squashfs) =="
  unsquashfs -l "$P/custom-disk/casper/minimal.standard.live.squashfs" 2>/dev/null | grep -E 'etc/(os-release|lsb-release)$|etc/skel/|etc/xdg/autostart/|usr/share/backgrounds/' | head -40
  echo "== standard layer (minimal.standard.squashfs) =="
  unsquashfs -l "$P/custom-disk/casper/minimal.standard.squashfs" 2>/dev/null | grep -E 'etc/(os-release|lsb-release)$|etc/skel/|etc/xdg/autostart/|usr/share/backgrounds/' | head -40
  echo "== sizes =="
  ls -l "$P/custom-disk/casper/"*.squashfs
} > "$OUT" 2>&1
echo DONE
