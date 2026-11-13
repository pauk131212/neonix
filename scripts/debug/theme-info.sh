#!/bin/bash
P=/home/builder/cubic-project
OUT=/media/sf_work/theme-info.txt
{
  echo "== themes =="
  ls "$P/custom-root/usr/share/themes"
  echo "== icons =="
  ls "$P/custom-root/usr/share/icons"
  echo "== skel xsettings =="
  cat "$P/custom-root/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 2>&1
  echo "== live user xfconf dir =="
  ls -la "$P/custom-root/home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>&1
  echo "== live user desktop xml =="
  cat "$P/custom-root/home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" 2>&1
  echo "== skel xfconf dir =="
  ls -la "$P/custom-root/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>&1
  echo "== neonix wallpaper =="
  ls -l "$P/custom-root/usr/share/backgrounds/neonix/" 2>&1
} > "$OUT" 2>&1
echo DONE
