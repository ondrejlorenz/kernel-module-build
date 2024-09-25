#!/usr/bin/env sh

check_module() {
    local module_name="$1"
    local module_number="$2"
    if lsmod | grep -q "^$module_name"; then
        echo "${module_number}/4 Module ${module_name}.ko correctly loaded"
    else
        echo "Something went wrong with ${module_name}.ko!"
    fi
}

check_module "can_dev" "1"
check_module "emuc2socketcan" "2"
check_module "m_can" "3"
check_module "m_can_pci" "4"

# A background sleep allows handling signals
exec /bin/sh -c "trap : TERM INT; sleep infinity & wait"
