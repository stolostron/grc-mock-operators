# Utilities for emulation (like qemu static binaries) may be required for multiarch
# builds. When not building on and for linux/amd64 (eg on Apple Silicon), the build
# args should be set specially for the best results. That should be handled by the
# `build-push-bundles.sh` script or Makefile.
ARG HOSTPLATFORM=linux/amd64
ARG TARGETOS=linux
ARG TARGETARCH=amd64

# Build the manager binary
FROM --platform=${HOSTPLATFORM} golang:1.22 AS builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/main.go cmd/main.go
COPY api/ api/
COPY internal/controller/ internal/controller/

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -o manager cmd/main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM --platform=${TARGETOS}/${TARGETARCH} gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
