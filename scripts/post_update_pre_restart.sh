#!/bin/bash

# this script will install the kernel headers and modules-extra for the latest installed kernel
latest_kernel=$(dpkg -l | grep linux-image | awk '{print $2}' | grep -E '^linux-image-[0-9]' | sed 's/^linux-image-//' | sort | uniq | tail -n1)

apt install linux-headers-$latest_kernel -y
apt install linux-modules-extra-$latest_kernel -y