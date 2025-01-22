#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

for dirpath in $(find ${BASE_DIR}/operators -type d -print -mindepth 1 -maxdepth 1)
    do
        cd "$dirpath"
        operator_name=$(basename ${dirpath})
        echo "* Handling operator ${operator_name} ..."
        build_img="quay.io/stolostron-grc/${operator_name}:latest"
        podman build --platform linux/amd64 -f Dockerfile -t ${build_img}
        podman push ${build_img}

        bundle_img="quay.io/stolostron-grc/${operator_name}-bundle:latest"
        make bundle IMG=$build_img
        podman build --platform linux/amd64 -f bundle.Dockerfile  -t ${bundle_img}
        podman push ${bundle_img}
    done
