#!/bin/bash
# Optional: enables SSH into the VM so the host can run commands remotely.
# Run inside the guest: bash /media/sf_work/build/enable-ssh.sh
set -u

echo "==> installing openssh-server"
sudo apt update
sudo apt install -y openssh-server

echo "==> enabling service"
sudo systemctl enable --now ssh

echo "==> status"
systemctl is-active ssh
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.'
echo "==> DONE"
