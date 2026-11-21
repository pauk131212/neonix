#!/bin/bash
# Патч initrd: докладывает DRM-драйверы (чтобы plymouth рисовал через DRM, а не fbcon)
# и копирует тему neonix внутрь initrd.
set -u
SRC=${SRC:-/media/sf_work/neonix}
P=${P:-/home/builder/cubic-project/custom-root}
K=${K:-7.0.0-31-generic}
ISO_INITRD=${ISO_INITRD:-/home/builder/cubic-project/custom-disk/casper/initrd.gz}
W=/tmp/initrd-mods
R=$W/root
OFFSET=${OFFSET:-65747456}   # смещение zstd-потока в initrd.gz (см. docs/rebuild-iso.md)

echo builder | sudo -S -v 2>/dev/null
rm -rf "$W"; mkdir -p "$R"; cd "$R"
echo "== распаковка initrd =="
head -c "$OFFSET" "$ISO_INITRD" > /tmp/initrd-prefix.bin
tail -c +$((OFFSET + 1)) "$ISO_INITRD" | zstd -d -c | cpio -idm --quiet
echo "entries: $(find . | wc -l)"

echo "== модули DRM =="
python3 - "$P" "$K" "$R" <<'PY'
import os, sys, shutil
P, K, R = sys.argv[1], sys.argv[2], sys.argv[3]
moddir = f"{P}/lib/modules/{K}"
dep = {}
for line in open(f"{moddir}/modules.dep", encoding="utf-8", errors="ignore"):
    if ':' not in line: continue
    src, deps = line.split(':', 1)
    dep[src.strip()] = [d for d in deps.split() if d]

roots = ["vmwgfx", "i915", "amdgpu", "nouveau", "radeon", "virtio_gpu",
         "drm_ttm_helper", "ttm", "drm_kms_helper", "drm_display_helper",
         "drm_exec", "drm_suballoc_helper", "drm_client_lib", "video",
         "cec", "i2c-algo-bit"]
want = set()

def find(name):
    return [p for p in dep if os.path.basename(p).startswith(name + ".ko")]

def resolve(path):
    if path in want: return
    want.add(path)
    for d in dep.get(path, []):
        resolve(d)

for r in roots:
    for p in find(r):
        resolve(p)

copied = total = 0
for rel in sorted(want):
    src = os.path.join(moddir, rel)
    if not os.path.exists(src):
        print("MISSING", rel); continue
    dst = os.path.join(R, "lib/modules", K, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)
    copied += 1
    total += os.path.getsize(src)
print(f"copied {copied} modules, {total/1024/1024:.1f} MiB")
PY

echo "== modprobe-файлы =="
sudo install -d "$R/lib/modules/$K"
for f in modules.dep modules.dep.bin modules.alias modules.alias.bin modules.builtin \
          modules.builtin.bin modules.order modules.softdep modules.symbols modules.symbols.bin; do
    [ -f "$P/lib/modules/$K/$f" ] && sudo cp -a "$P/lib/modules/$K/$f" "$R/lib/modules/$K/$f"
done

echo "== тема в initrd =="
TH="$R/usr/share/plymouth/themes/neonix"
sudo rm -rf "$TH"; sudo mkdir -p "$TH"
sudo cp -a "$P/usr/share/plymouth/themes/neonix/." "$TH/"
echo "neonix files now: $(ls "$TH" | wc -l)"

echo "== упаковка =="
rm -f /tmp/main-mods.zst /tmp/initrd-mods.gz
cd "$R"
find . -print0 | cpio --null -o -H newc --quiet | zstd -19 -T0 -c > /tmp/main-mods.zst
cat /tmp/initrd-prefix.bin /tmp/main-mods.zst > /tmp/initrd-mods.gz
ls -l /tmp/initrd-mods.gz
sudo cp -f /tmp/initrd-mods.gz "$ISO_INITRD"
sudo chown builder:builder "$ISO_INITRD"
chmod 444 "$ISO_INITRD"
ls -l "$ISO_INITRD"
echo DONE
