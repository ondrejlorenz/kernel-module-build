#!/usr/bin/env bash

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
    local files_url="https://files.balena-cloud.com/images"
    local filename
    local url

    url="${files_url}/${slug}/${version//+/%2B}/kernel_modules_headers.tar.gz"
    echo "Fetching headers from URL: $url"  # Echo the URL
    tmp_path=$(mktemp --directory)
    cd $tmp_path

    if ! wget --quiet "$url"; then
        echo "Could not find headers for '$slug' at version '$version'"
        exit 1
    fi

    filename=$(basename $url)
    strip_depth=$(tar tf ${filename} | grep "/\.config$" | tr -dc / | wc -c)
    if ! tar -xf $filename --strip $strip_depth; then
        rm -rf "$tmp_path"
        echo "Unable to extract $tmp_path/$filename."
        exit 1
    fi

    echo "${tmp_path}"
}

main() {
    local src_dir=
    local output_dir=
    local os_version
    local slug="genericx86-64-ext"

    ## Sanity checks
    if [ ${#} -eq 0 ] ; then
        usage
        exit 1
    else
        while getopts "hi:o:v:s:" c; do
            case "${c}" in
                i) src_dir="${OPTARG:-}";;
                o) output_dir="${OPTARG:-}";;
                v) os_version="${OPTARG:-}";;
                s) slug="${OPTARG:-genericx86-64-ext}";;
                h) usage;;
                *) usage; exit 1;;
            esac
        done

        # Sanity checks
        [ -z "${src_dir}" ] && echo "No module source directory provided" && exit 1
        [ -z "${output_dir}" ] && echo "No output directory provided" && exit 1
        [ -z "${os_version}" ] && echo "No OS version specified" && exit 1

        output_dir="${output_dir}/${src_dir}_${slug}_${os_version}"
        echo "Preparing to install headers for:
            OS version: ${os_version}
            Device type: ${slug}"

        rm -rf "$output_dir"
        mkdir -p "$output_dir"
        cp -dR "$src_dir"/* "$output_dir"

        fetch_headers "${slug}" "${os_version}"

        echo "Headers installed in ${output_dir}"
    fi
}

main "${@}"
