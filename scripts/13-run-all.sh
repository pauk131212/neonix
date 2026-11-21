#!/bin/sh
# Всё подряд: тема + сессия + сборка ISO.
#   SRC=/media/sf_work/neonix bash 13-run-all.sh
set -u
SRC=${SRC:-/media/sf_work/neonix}
echo "=== THEME $(date +%T) ==="
bash "$SRC/scripts/09-apply-theme.sh"
echo "=== TWEAKS $(date +%T) ==="
bash "$SRC/scripts/10-apply-tweaks.sh"
echo "=== BUILD $(date +%T) ==="
bash "$SRC/scripts/12-build-final.sh"
echo "=== ALL DONE $(date +%T) ==="
