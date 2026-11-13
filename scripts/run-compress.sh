#!/bin/bash
# Edit installer source name, then recompress the root file system.
P=/home/builder/cubic-project
D=$P/custom-disk

sed -i 's/Ubuntu 24.04.5 2026.11.09 LTS/Neonix 1.0/; s/Custom Noble Numbat/Neonix 1.0 (Noble)/' "$D/casper/install-sources.yaml"
cat "$D/casper/install-sources.yaml" > /media/sf_work/install-sources.txt 2>&1

echo builder | sudo -S bash /media/sf_work/build/compress.sh > /tmp/compress.log 2>&1
cp /tmp/compress.log /media/sf_work/compress.log
echo DONE > /media/sf_work/compress.done
