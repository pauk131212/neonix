#!/bin/bash
P=/home/builder/cubic-project
S=$P/custom-root
T=$P/custom-disk/casper/minimal.squashfs

date
df -h /
mksquashfs "$S" "$T" -noappend -comp zstd -wildcards \
    -e "proc/*" -e "proc/.*" -e "run/*" -e "run/.*" \
    -e "tmp/*" -e "tmp/.*" -e "var/crash/*" -e "var/crash/.*" \
    -e "swapfile" -e "root/.bash_history" -e "root/.cache" -e "root/.wget-hsts" \
    -e "home/*/.bash_history" -e "home/*/.cache" -e "home/*/.wget-hsts"
echo "MKSQUASHFS_EXIT=$?"
ls -l "$T"
date
