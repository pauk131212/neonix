#!/bin/bash
set -e
P=/home/builder/cubic-project
R=$P/custom-root
OUT=/media/sf_work/release.txt

sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Neonix 1.0"/' "$R/usr/lib/os-release"
sed -i 's/^DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION="Neonix 1.0"/' "$R/etc/lsb-release"

{
    echo "== os-release =="
    grep -E '^(PRETTY_NAME|NAME|VERSION|ID)=' "$R/usr/lib/os-release"
    echo "== lsb-release =="
    cat "$R/etc/lsb-release"
    echo "== disk =="
    df -h /
} > "$OUT" 2>&1
echo DONE
