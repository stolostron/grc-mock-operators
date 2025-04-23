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
        ${CONTAINER_TOOL} build -f Dockerfile -t "${build_img}-${arch}" \
          --platform "linux/${arch}" --build-arg "TARGETARCH=${arch}" \
          --build-arg "HOSTPLATFORM=${host_platform}" .
        ${CONTAINER_TOOL} push "${build_img}-${arch}"
        echo "::endgroup::"
    done

    echo "::group::Building multiarch image and bundle for ${operator_name}"
    ${CONTAINER_TOOL} manifest rm "${build_img}" || true
    ${CONTAINER_TOOL} manifest create "${build_img}" "${build_img}-amd64" \
      "${build_img}-arm64" "${build_img}-s390x" "${build_img}-ppc64le"

    if [[ "${CONTAINER_TOOL}" == "podman" ]]; then
        podman manifest push "${build_img}" "${build_img}"
    else
        docker manifest push "${build_img}"
    fi

    bundle_img="quay.io/stolostron-grc/${operator_name}-bundle:latest"
    make bundle "IMG=${build_img}"
    ${CONTAINER_TOOL} build -f bundle.Dockerfile -t ${bundle_img} .
    ${CONTAINER_TOOL} push ${bundle_img}

    echo "::endgroup::"
done
