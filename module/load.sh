#!/usr/bin/env sh
OS_VERSION=$(echo "$BALENA_HOST_OS_VERSION" | cut -d " " -f 2)
echo "OS Version is $OS_VERSION"

# NOTE: some modules need to be loaded in a specific order
# if that's the case, replace the loop below with a list of
# `insmod $mod_dir/<module>.ko` commands in the right order
cd /usr/src/app
mkdir modules
find ./out/ -name "*.ko" -exec cp {} ./modules/ \;

insmod ./modules/can-dev.ko
insmod ./modules/emuc2socketcan.ko
insmod ./modules/m_can.ko
insmod ./modules/m_can_pci.ko

tail -f /dev/null