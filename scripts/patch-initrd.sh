#!/bin/bash
# Пересобрать casper/initrd.gz с темой Neonix внутри zstd-части.
#
# Раскладка casper/initrd.gz у Ubuntu 24.04.5:
#   0            cpio: микрокод AuthenticAMD
#   305 784      cpio: микрокод GenuineIntel
#   15 106 560   cpio: прошивки (/usr/lib/firmware)
#   65 747 456   zstd-сжатый основной initrd (init, plymouth, casper)
#
# Скрипт распаковывает только последнюю часть, кладёт тему Plymouth,
# плагин script.so, plymouthd.conf и собирает файл заново. Первые
# 65 747 456 байт копируются байт в байт.
set -e
P=/home/builder/cubic-project
F=$P/custom-disk/casper/initrd.gz
W=/tmp/initrd-x
R=$W/root
OUT=/media/sf_work/patch-initrd.txt
OFFSET=65747456

echo "clean + extract"
rm -rf "$W"
mkdir -p "$R"
cd "$R"
tail -c +$((OFFSET + 1)) "$F" | zstd -d -c | cpio -idm --quiet
echo "extracted: $(find . | wc -l) entries"

echo "apply theme"
rm -rf "$R/usr/share/plymouth/themes/neonix"
install -d "$R/usr/share/plymouth/themes/neonix"
cp -a "$P/custom-root/usr/share/plymouth/themes/neonix/." "$R/usr/share/plymouth/themes/neonix/"
cp "$P/custom-root/usr/lib/x86_64-linux-gnu/plymouth/script.so" "$R/usr/lib/x86_64-linux-gnu/plymouth/script.so"
install -d "$R/etc/plymouth"
printf '[Daemon]\nTheme=neonix\nShowDelay=0\nDeviceTimeout=8\n' > "$R/etc/plymouth/plymouthd.conf"
ln -sfn /usr/share/plymouth/themes/neonix/neonix.plymouth "$R/usr/share/plymouth/themes/default.plymouth"

echo "repack"
rm -f /tmp/main-new.zst /tmp/initrd-new.gz
cd "$R"
find . -print0 | cpio --null -o -H newc --quiet | zstd -19 -T0 -c > /tmp/main-new.zst

head -c $OFFSET "$F" > /tmp/initrd-new.gz
cat /tmp/main-new.zst >> /tmp/initrd-new.gz
cp /tmp/initrd-new.gz "$F"
chown builder:builder "$F"
chmod 444 "$F"

{
  echo "== new initrd =="
  ls -l "$F"
  echo "== theme files =="
  ls "$R/usr/share/plymouth/themes/neonix"
  echo "== script md5 =="
  md5sum "$R/usr/share/plymouth/themes/neonix/neonix.script"
  echo "== conf =="
  cat "$R/etc/plymouth/plymouthd.conf"
  echo "== verify zstd part =="
  tail -c +$((OFFSET + 1)) "$F" | zstd -d -c 2>/dev/null | cpio -t 2>/dev/null | grep -i 'themes/neonix' | head -5
} > "$OUT" 2>&1
echo DONE
