#!/bin/bash
set -e
F=/home/builder/cubic-project/custom-disk/casper/initrd.gz
W=/tmp/initrd-x
OUT=/media/sf_work/initrd5.txt
rm -rf "$W"
mkdir -p "$W/early" "$W/main" "$W/extra"

python3 - "$F" <<'PY'
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
    j = d.find(b'070701', o + 122)
    starts.append(j)
starts.append(len(d))
print('offsets:', starts, file=sys.stderr)
for k in range(3):
    open('/tmp/part%d' % k, 'wb').write(d[starts[k]:starts[k+1]])
PY

cd "$W/early" && cpio -idm --quiet < /tmp/part0
cd "$W/main" && cpio -idm --quiet < /tmp/part1
cd "$W/extra" && cpio -idm --quiet < /tmp/part2

{
  echo "== early =="
  ( cd "$W/early" && find . -type f | wc -l && find . -type f | head -8 )
  echo "== main top =="
  ( cd "$W/main" && ls )
  echo "== main plymouth dir =="
  ( cd "$W/main" && ls -la usr/lib/x86_64-linux-gnu/plymouth 2>&1 | head -20 )
  echo "== main themes =="
  ( cd "$W/main" && ls usr/share/plymouth/themes 2>&1 )
  echo "== main plymouthd.conf =="
  ( cd "$W/main" && cat etc/plymouth/plymouthd.conf 2>&1 )
  echo "== main count =="
  ( cd "$W/main" && find . -type f | wc -l )
  echo "== extra top =="
  ( cd "$W/extra" && ls )
  echo "== extra plymouth dir =="
  ( cd "$W/extra" && ls -la usr/lib/x86_64-linux-gnu/plymouth 2>&1 | head -20 )
  echo "== extra themes =="
  ( cd "$W/extra" && ls usr/share/plymouth/themes 2>&1 )
  echo "== extra count =="
  ( cd "$W/extra" && find . -type f | wc -l )
} > "$OUT" 2>&1
echo DONE
