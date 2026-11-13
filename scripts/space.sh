#!/bin/bash
# Disk/project diagnostics for the Neonix builder VM.
echo "== df -h =="
df -h /
echo
echo "== lsblk =="
lsblk
echo
echo "== project top-level =="
ls -lah "$HOME/cubic-project" 2>/dev/null
echo
echo "== project usage (depth 2) =="
du -h --max-depth=2 "$HOME/cubic-project" 2>/dev/null | sort -h | tail -30
echo
echo "== biggest files =="
find "$HOME/cubic-project" -type f -size +200M -printf '%s\t%p\n' 2>/dev/null | sort -n | tail -15
