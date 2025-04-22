#!/bin/bash

set -ex

CONTAINER_TOOL="${CONTAINER_TOOL:-podman}"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

if [[ "${CONTAINER_TOOL}" == "podman" ]]; then
    host_platform="$(podman info --format '{{.Version.OsArch}}')"
else
    host_platform="$(docker info --format '{{.ClientInfo.Os}}/{{.ClientInfo.Arch}}')"
fi

for dirpath in $(find ${BASE_DIR}/operators -type d -print -mindepth 1 -maxdepth 1)
do
    cd "$dirpath"
    operator_name=$(basename ${dirpath})
    echo "* Handling operator ${operator_name} ..."
    
    build_img="quay.io/stolostron-grc/${operator_name}:latest"
    for arch in amd64 arm64 s390x ppc64le
    do
        echo "::group::Building ${operator_name} for ${arch}"
        ${CONTAINER_TOOL} build -f Dockerfile -t "${operator_name}-${arch}" \
          --platform "linux/${arch}" --build-arg "TARGETARCH=${arch}" \
          --build-arg "HOSTPLATFORM=${host_platform}"
        echo "::endgroup::"
    done
    ${CONTAINER_TOOL} manifest create "${build_img}" "${operator_name}-amd64" \
      "${operator_name}-arm64" "${operator_name}-s390x" "${operator_name}-ppc64le"

    if [[ "${CONTAINER_TOOL}" == "podman" ]]; then
        echo podman manifest push "${build_img}" "${build_img}"
    else
        echo docker manifest push "${build_img}"
    fi
    echo "(faked)"

    bundle_img="quay.io/stolostron-grc/${operator_name}-bundle:latest"
    make bundle IMG=$build_img
    ${CONTAINER_TOOL} build -f bundle.Dockerfile -t ${bundle_img}
    echo ${CONTAINER_TOOL} push ${bundle_img}
    echo "(faked)"
done
