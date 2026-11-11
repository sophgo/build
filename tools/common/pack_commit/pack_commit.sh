#!/bin/bash

# Writes the header to repo_commits

# If *.xml files exist: runs parse_xml_for_commits
# Otherwise: runs read_from_toppath_for_commits
# You can copy *.xml files from cvi_manifest to the current directory.
# cp cvi_manifest/mars3/mars3_dev.xml build/tools/common/pack_commit/
# Copies the result to $OUTPUT_DIR/data

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OUTPUT_FILE="${SCRIPT_DIR}/repo_commits"

validate_env() {
    if [[ -z "${TOP_DIR}" ]]; then
        echo "ERROR: TOP_DIR environment variable not set!" >&2
        exit 1
    fi
    if [[ -z "${ROOTFS_DIR}" ]]; then
        echo "ERROR: ROOTFS_DIR environment variable not set!" >&2
        exit 1
    fi

}

process_repo() {
    local display_path="$1"
    local repo_path="$2"

    if [[ ! -d "${repo_path}" ]]; then
        echo "${display_path} missing" >> "${OUTPUT_FILE}"
        return 1
    fi

    pushd "${repo_path}" >/dev/null || return 1

    if [[ -e ".git" ]]; then
        local commit_id=$(git rev-parse --short HEAD 2>/dev/null)
        if [[ -z "${commit_id}" ]]; then
            echo "${display_path} no-commits" >> "${OUTPUT_FILE}"
            popd >/dev/null
            return 1
        fi

        local branch_name=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "DETACHED")
        echo "${display_path} ${commit_id} ${branch_name}" >> "${OUTPUT_FILE}"
    else
        echo "${display_path} non-git" >> "${OUTPUT_FILE}"
    fi

    popd >/dev/null
}


parse_xml_for_commits() {
    [[ ! -f "${xml_file}" ]] && return

    while IFS= read -r line; do
        local repo=$(sed -n 's/.*<project name="\([^"]*\).*/\1/p' <<< "$line")
        local path=$(sed -n 's/.*path="\([^"]*\).*/\1/p' <<< "$line")

        [[ -z "${repo}" || -z "${path}" ]] && continue
        process_repo "${path}" "${TOP_DIR}/${path}"
    done < "${xml_file}"
}


read_from_toppath_for_commits() {
    while IFS= read -r -d $'\0' repo_path; do
        process_repo "$(basename "${repo_path}")" "${repo_path}"
    done < <(find "${TOP_DIR}" -maxdepth 1 -mindepth 1 -type d -print0)
}

main() {
    validate_env
    echo "repo commit-id branch" > "${OUTPUT_FILE}"
    pushd "$SCRIPT_DIR" >/dev/null

    local xml_file
    xml_file=$(ls *.xml 2>/dev/null | head -1)

    if [[ -n "${xml_file}" ]]; then
        echo "pack_xml:${xml_file}."
        parse_xml_for_commits
    else
        echo "pack_path"
        read_from_toppath_for_commits
    fi

    column -t -s " " "${OUTPUT_FILE}"  > "${ROOTFS_DIR}/repo_commits"
    echo "Generated at: $(date)" >> "${ROOTFS_DIR}/repo_commits"
    rm -f "${OUTPUT_FILE}"
    popd >/dev/null
}

main
