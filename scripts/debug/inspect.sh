#!/bin/bash
# Copy files needed for inspection to the shared folder.
sudo cp /home/builder/cubic-project/custom-disk/boot/grub/grub.cfg /media/sf_work/grub.cfg
sudo cp /home/builder/cubic-project/custom-disk/boot/grub/loopback.cfg /media/sf_work/loopback.cfg
sudo cp /usr/share/cubic/commands/compress-root /media/sf_work/compress-root
sudo ls -la /home/builder/cubic-project/custom-disk/boot/grub/ > /media/sf_work/grubdir.txt 2>&1
sudo chown builder:builder /media/sf_work/grub.cfg /media/sf_work/loopback.cfg /media/sf_work/compress-root
echo DONE
