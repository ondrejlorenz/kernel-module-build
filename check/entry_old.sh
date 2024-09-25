#!/usr/bin/env sh

if dmesg | grep -q "can_dev"; then
	echo "1/4 Module can_dev.ko correctly loaded"
else
	echo "Something went wrong with can_dev.ko!"
	
fi
if dmesg | grep -q "emuc2socketcan"; then
	echo "2/4Module emuc2socketcan.ko correctly loaded"
else
	echo "Something went wrong with emuc2socketcan.ko!"
	
fi
if dmesg | grep -q "m_can"; then
	echo "3/4 Module m_can.ko correctly loaded"
else
	echo "Something went wrong with m_can.ko!"
	
fi
if dmesg | grep -q "m_can_pci"; then
	echo "4/4Module m_can_pci.ko correctly loaded"
else
	echo "Something went wrong with m_can_pci.ko!"
	
fi

# A background sleep allows to handle signals
exec /bin/sh -c "trap : TERM INT; sleep 9999999999d & wait"

tail -f /dev/null