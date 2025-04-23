#!/bin/bash

set -ex

CONTAINER_TOOL="${CONTAINER_TOOL:-podman}"

CATALOG_IMG="${CATALOG_IMG:-quay.io/stolostron-grc/grc-mock-operators-catalog}"
CATALOG_TAG="${CATALOG_TAG:-latest}"

manifest="${CATALOG_IMG}:${CATALOG_TAG}"

for arch in amd64 arm64 s390x ppc64le
do
    echo "::group::Building catalog image for ${arch}"
    ${CONTAINER_TOOL} build -f catalog.Dockerfile -t "${manifest}-${arch}" \
      --platform "linux/${arch}" .
    ${CONTAINER_TOOL} push "${manifest}-${arch}" 
    echo "::endgroup::"
done

echo "::group::Building multiarch manifest for catalog"
${CONTAINER_TOOL} manifest rm "${manifest}" || true
${CONTAINER_TOOL} manifest create "${manifest}" "${manifest}-amd64" \
  "${manifest}-arm64" "${manifest}-s390x" "${manifest}-ppc64le"

if [[ "${CONTAINER_TOOL}" == "podman" ]]; then
    podman manifest push "${manifest}" "${manifest}"
else
    docker manifest push "${manifest}"
fi
echo "::endgroup::"
