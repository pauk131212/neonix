#!/bin/bash
P=/home/builder/cubic-project
OUT=/media/sf_work/state.txt
{
  echo "== theme dir =="
  ls -la "$P/custom-root/usr/share/plymouth/themes/neonix" 2>&1
  echo "== themes =="
  ls "$P/custom-root/usr/share/plymouth/themes/" 2>&1
  echo "== plugin =="
  ls -la "$P/custom-root/usr/lib/x86_64-linux-gnu/plymouth/" 2>&1
  echo "== initrd type =="
  file "$P/custom-disk/casper/initrd.gz" 2>&1
  echo "== initrd size =="
  ls -l "$P/custom-disk/casper/initrd.gz" 2>&1
  echo "== initrd listing head =="
  gzip -dc "$P/custom-disk/casper/initrd.gz" 2>/dev/null | cpio -t 2>/dev/null | head -25
  echo "== autostart =="
  ls -la "$P/custom-root/etc/xdg/autostart/" 2>&1 | head -20
  echo "== skel desktop xml =="
  ls -la "$P/custom-root/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>&1
  echo "== live user home =="
  ls -la "$P/custom-root/home/" 2>&1
} > "$OUT" 2>&1
echo DONE
