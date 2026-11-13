#!/bin/bash
set -e
F=/home/builder/cubic-project/custom-disk/casper/initrd.gz
W=/tmp/initrd-x
OUT=/media/sf_work/initrd4.txt
rm -rf "$W"
mkdir -p "$W/early" "$W/main" "$W/extra"

python3 - "$F" > /tmp/initrd-offsets.txt <<'PY'
import sys
F = sys.argv[1]
d = open(F, 'rb').read()
offs = []
i = 0
while True:
    i = d.find(b'TRAILER!!!', i)
    if i < 0:
        break
    offs.append(i)
    i += 10
starts = [0]
for o in offs[:-1]:
    e = o + 122
    a = (e + 511) // 512 * 512
    starts.append(a)
print(len(d))
for s in starts:
    print(s)
PY

mapfile -t OFF < /tmp/initrd-offsets.txt
TOTAL=${OFF[0]}
S0=${OFF[1]}
S1=${OFF[2]}
S2=${OFF[3]}

echo "total=$TOTAL starts=$S0,$S1,$S2" > "$OUT"

cd "$W/early"
dd if="$F" bs=1 skip=0 count="$S0" status=none | cpio -idm --quiet
cd "$W/main"
dd if="$F" bs=1 skip="$S0" count=$((S1 - S0)) status=none | cpio -idm --quiet
cd "$W/extra"
dd if="$F" bs=1 skip="$S1" count=$((TOTAL - S1)) status=none | cpio -idm --quiet

{
  echo "== early files =="
  ( cd "$W/early" && find . -type f | head -10 && find . -type f | wc -l )
  echo "== main top =="
  ( cd "$W/main" && ls )
  echo "== main plymouth =="
  ( cd "$W/main" && ls -la usr/lib/x86_64-linux-gnu/plymouth 2>&1 | head -20 )
  ( cd "$W/main" && ls -la usr/share/plymouth/themes 2>&1 | head -20 )
  ( cd "$W/main" && cat etc/plymouth/plymouthd.conf 2>&1 )
  echo "== main file count =="
  ( cd "$W/main" && find . -type f | wc -l )
  echo "== extra top =="
  ( cd "$W/extra" && ls )
  echo "== extra plymouth =="
  ( cd "$W/extra" && ls -la usr/lib/x86_64-linux-gnu/plymouth 2>&1 | head -20 )
  ( cd "$W/extra" && ls -la usr/share/plymouth/themes 2>&1 | head -20 )
  echo "== extra file count =="
  ( cd "$W/extra" && find . -type f | wc -l )
} >> "$OUT" 2>&1
echo DONE
