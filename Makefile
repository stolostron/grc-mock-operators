CONTAINER_TOOL ?= podman
TAG ?= latest
CATALOG_IMG = quay.io/stolostron-grc/grc-mock-operators-catalog:$(TAG)

LOCALBIN ?= $(PWD)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

build-bundles:
	./build/build-push-bundles.sh

.PHONY: opm
OPM = $(LOCALBIN)/opm
opm: ## Download opm locally if necessary.
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	OS=$(shell go env GOOS) && ARCH=$(shell go env GOARCH) && \
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v1.50.0/$${OS}-$${ARCH}-opm ;\
	chmod +x $(OPM) ;\
	}
else
OPM = $(shell which opm)
endif
endif

.PHONY: catalog-build-push
catalog-build-push: opm
	$(OPM) validate ./catalog
	$(CONTAINER_TOOL) build -f catalog.Dockerfile -t $(CATALOG_IMG)
	$(CONTAINER_TOOL) push $(CATALOG_IMG)
