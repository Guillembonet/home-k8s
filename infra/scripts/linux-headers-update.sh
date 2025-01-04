#!/bin/bash

# this script will install the kernel headers and modules-extra for the latest installed kernel
latest_kernel=$(dpkg -l | grep linux-image | awk '{print $2}' | grep -E '^linux-image-[0-9]' | sed 's/^linux-image-//' | sort | uniq | tail -n1)
current_kernel=$(uname -r)

# if the latest kernel is the same as the current kernel, then exit
if [ "$latest_kernel" == "$current_kernel" ]; then
    echo "The latest kernel is already installed"
    exit 0
fi

apt install linux-headers-$latest_kernel -y
apt install linux-modules-extra-$latest_kernel -y