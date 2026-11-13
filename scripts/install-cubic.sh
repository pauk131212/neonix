#!/bin/bash
# Installs Cubic from the official PPA (ppa:cubic-wizard/release).
# The old ppa:cubic-workshop/ppa no longer exists (404).
# Run: bash /media/sf_work/build/install-cubic.sh
set -u

echo "==> apt update"
sudo apt update || true

echo "==> enabling universe"
sudo add-apt-repository -y universe

echo "==> removing old cubic-workshop PPA entries (if any)"
sudo rm -f /etc/apt/sources.list.d/*cubic-workshop* 2>/dev/null || true

if compgen -G "/etc/apt/sources.list.d/*cubic-wizard*" > /dev/null; then
    echo "==> PPA already configured"
else
    echo "==> adding PPA cubic-wizard/release (up to 5 attempts)"
    ok=0
    for i in 1 2 3 4 5; do
        if sudo add-apt-repository -y ppa:cubic-wizard/release; then
            ok=1
            break
        fi
        echo "    attempt $i failed, retrying in 5s..."
        sleep 5
    done
    if [ "$ok" -ne 1 ]; then
        echo "ERROR: could not add PPA after 5 attempts."
        echo "Check network, then re-run this script."
        exit 1
    fi
fi

echo "==> apt update"
sudo apt update

echo "==> installing cubic"
sudo apt install -y --no-install-recommends cubic

echo
echo "==> DONE. Launch with: cubic"
