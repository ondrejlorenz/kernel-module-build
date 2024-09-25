#!/usr/bin/env bash

. include/logging

set -o errexit
set -o pipefail

readonly script_name=$(basename "${0}")

usage() {
    cat <<EOF
Usage: ${script_name} [OPTIONS]
        -i Source directory (default to ./src)
        -o Output directory (default to ./out)
        -v balenaOS version (mandatory)
        -s BalenaCloud slug name (mandatory)
        -h Display usage
EOF
}

fetch_headers() {
    local slug="${1}"
    local version="${2}"
    local files_url="https://files.balena-cloud.com"
    local esr_pattern="^[1-3][0-9]{3}\.(1|01|4|04|7|07||10)\.[0-9]*(.dev|.prod)?$"
    local image_path="images"
    local filename
    local url

    if [[ ${version} =~ ${esr_pattern} ]]; then
        image_path="esr-images"
    fi

    url="${files_url}/${image_path}/${slug}/${version//+/%2B}/kernel_modules_headers.tar.gz"
    tmp_path=$(mktemp --directory)
    cd $tmp_path

    if ! wget --quiet $(echo "$url" | sed -e 's/+/%2B/g'); then
        fail "Could not find headers for '$slug' at version '$version'"
    fi

    filename=$(basename $url)
    # Count paths to strip by looking for .config and counting forward slashes
    strip_depth=$(tar tf ${filename} | grep "/\.config$" | tr -dc / | wc -c)
    if ! tar -xf $filename --strip $strip_depth; then
        fail "Unable to extract $tmp_path/$filename."
    fi
    /usr/src/app/workarounds.sh "${slug}" "${version}" "${tmp_path}"
    echo "${tmp_path}"
}

fetch_vanilla_module() {
    local version="${1}"
    local module_path="${2}"
    local files_url="https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x"
    local filename="linux-${version}.tar.gz"
    local url="${files_url}/${filename}"
    local tmp_path=$(mktemp --directory)

    cd $tmp_path

    if ! wget --quiet "$url"; then
        fail "Could not download vanilla kernel version '$version'"
    fi

    if ! tar -xf $filename; then
        fail "Unable to extract $filename."
    fi

    local kernel_dir="${tmp_path}/linux-${version}"
    local module_src="${kernel_dir}/${module_path}"
    if [ ! -d "${module_src}" ]; then
        fail "Module path '${module_src}' does not exist."
    fi

    echo "${module_src}"
}

inject_makefile_config() {
    local makefile="${1}"
    if [ -f "${makefile}" ]; then
        echo "obj-m += m_can.o" >> "${makefile}"
        echo "obj-m += m_can_pci.o" >> "${makefile}"
        echo "obj-m += m_can_platform.o" >> "${makefile}"
        echo "obj-m += tcan4x5x.o" >> "${makefile}"
    else
        fail "Makefile in ${makefile} does not exist."
    fi
}

build_module() {
    local headers_dir="${1}"
    local output_dir="${2}"
    local module_src="${3}"

    mkdir -p "${output_dir}"
    cd "${output_dir}"

    # Copy the vanilla module source to the output directory
    cp -r "${module_src}"/* .

    # Inject the Makefile configuration
    inject_makefile_config "Makefile"

    make -C "${headers_dir}" modules_prepare
    make -C "${headers_dir}" M="$PWD" modules
}

main() {
    local src_dir=
    local output_dir=
    local os_version="${OS_VERSION}"
    local slug=
    local vanilla_version="5.15.150"
    local module_path="drivers/net/can/m_can"

    if [ ${#} -eq 0 ] ; then
        usage
        exit 1
    else
        while getopts "hi:o:v:s:" c; do
            case "${c}" in
                i) src_dir="${OPTARG:-}";;
                o) output_dir="${OPTARG:-}";;
                v) os_version="${OPTARG:-}";;
                s) slug="${OPTARG:-}";;
                h) usage;;
                *) usage;exit 1;;
            esac
        done

        [ -z "${src_dir}" ] && fail "No module source directory provided"
        [ -z "${output_dir}" ] && fail "No output directory provided"
        [ -z "${os_version}" ] && fail "No OS versions specified"
        [ -z "${slug}" ] && fail "No slugs specified"

        output_dir="${output_dir}/${src_dir}_${slug}_${os_version}"
        info "Building source from ${src_dir} into ${output_dir} for:
            OS versions: ${os_version}
            Device types: ${slug}"

        mkdir -p "$output_dir"
        cp -dR "$src_dir"/* "$output_dir"

        headers_dir=$(fetch_headers "${slug}" "${os_version}")
        module_src=$(fetch_vanilla_module "${vanilla_version}" "${module_path}")

        build_module "${headers_dir}" "${output_dir}" "${module_src}"
    fi
}

main "${@}"

#manually
#./build3.sh -s genericx86-64-ext -v 5.3.21+rev3 -i driver -o ./out
