#!/bin/bash

set -ex

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
host_platform="$(podman info --format '{{.Version.OsArch}}')"

for dirpath in $(find ${BASE_DIR}/operators -type d -print -mindepth 1 -maxdepth 1)
do
    cd "$dirpath"
    operator_name=$(basename ${dirpath})
    echo "* Handling operator ${operator_name} ..."
    
    podman manifest rm "${operator_name}" || true
    podman manifest create "${operator_name}"
    build_img="quay.io/stolostron-grc/${operator_name}:latest"
    for arch in amd64 arm64 s390x ppc64le
    do
        echo "::group::Building ${operator_name} for ${arch}"
        podman build -f Dockerfile --manifest "${operator_name}" \
          --platform "linux/${arch}" --build-arg "TARGETARCH=${arch}" \
          --build-arg "HOSTPLATFORM=${host_platform}"
        echo "::endgroup::"
    done
    echo podman manifest push "${operator_name}" "${build_img}"
    echo "(faked)"

    bundle_img="quay.io/stolostron-grc/${operator_name}-bundle:latest"
    make bundle IMG=$build_img
    podman build -f bundle.Dockerfile  -t ${bundle_img}
    echo podman push ${bundle_img}
    echo "(faked)"
done
