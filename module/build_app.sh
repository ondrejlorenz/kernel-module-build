#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -x  # Enable debugging output

readonly script_name=$(basename "${0}")

usage() {
    cat <<EOF
Usage: ${script_name} [OPTIONS]
        -i Source directory (default to ./src)
        -o Output directory (default to ./out)
        -h Display usage
EOF
}

build_application() {
    local src_dir="${1%/}"  # Remove trailing slash if any
    local output_dir="${2%/}"  # Remove trailing slash if any

    mkdir -p "${output_dir}"
    cd "${output_dir}"
    echo "Copying files from ${src_dir} to ${output_dir}"
    cp -dR "${src_dir}/." .

    make
}

main() {
    local src_dir=
    local output_dir=

    ## Sanity checks
    if [ ${#} -eq 0 ] ; then
        usage
        exit 1
    else
        while getopts "hi:o:" c; do
            case "${c}" in
                i) src_dir=$(realpath "${OPTARG}");;  # Use absolute path
                o) output_dir=$(realpath "${OPTARG}");;  # Use absolute path
                h) usage;;
                *) usage; exit 1;;
            esac
        done

        # Sanity checks
        [ -z "${src_dir}" ] && { echo "No source directory provided"; exit 1; }
        [ -z "${output_dir}" ] && { echo "No output directory provided"; exit 1; }

        output_dir="${output_dir}/app_build"
        mkdir -p "${output_dir}"  # Ensure the output directory exists
        echo "Building application from ${src_dir} into ${output_dir}"

        build_application "${src_dir}" "${output_dir}"
    fi
}

main "${@}"
