# GRC Mock Operators

This repository contains operator bundles used for testing GRC operator policies.

---

## Adding Operators

### Install `operator-sdk`

To use the `operator-sdk` CLI tool, install it as follows:

- **For macOS (using Homebrew):**

  ```sh
  brew install operator-sdk
  ```

- **For other platforms:** Follow the
  [official installation guide](https://sdk.operatorframework.io/docs/installation/).

---

### Add an Operator

1. **Create a directory for the operator:**

   ```sh
   cd operators
   mkdir memcached-operator
   cd memcached-operator
   operator-sdk init --domain grc-mock.io --repo github.com/stolostron/grc-mock-operators/memcached-operator
   ```

2. **Create an API:**

   ```sh
   operator-sdk create api --group memcached.grc-mock.io --version v1 --kind Memcached --resource --controller
   ```

3. **Open a pull request:**

   Open a pull request with the new operator and request that the image repositories be created in Quay. The CI will ensure that the pull request images can be properly pushed.
   You can check the images at:
   [https://quay.io/organization/stolostron-grc](https://quay.io/organization/stolostron-grc).

---

## Adding to the Catalog

1. **Create a directory for the operator in the catalog:**

   ```sh
   cd catalog
   mkdir memcached-operator
   cd memcached-operator
   ```

2. **Generate the catalog for the operator:**

   ```sh
   cd ../.. # Return to the source directory
   make opm # install opm in your bin
   ./bin/opm init memcached-operator --default-channel=stable --output yaml > catalog/memcached-operator/index.yaml
   ./bin/opm render quay.io/stolostron-grc/memcached-operator-bundle:latest --output yaml >> catalog/memcached-operator/index.yaml
   ```

3. **Add a channel entry for the bundle:**

   ```sh
   cat << EOF >> catalog/memcached-operator/index.yaml
   ---
   schema: olm.channel
   package: memcached-operator
   name: stable
   entries:
     - name: memcached-operator.v0.1.0
   EOF
   ```

4. **Validate the catalog:**

   ```sh
   ./bin/opm validate catalog
   echo $?
   ```

5. **Open a pull request:**

   Open a pull request with the new catalog and request that the image repositories be created in Quay. The CI will ensure that the pull request images can be properly pushed.
   You can check the images at:
   [https://quay.io/organization/stolostron-grc](https://quay.io/organization/stolostron-grc).

---

## Testing the Operator in a Local Cluster

### Prerequisites

- A Kubernetes cluster (e.g., a `kind` cluster).

1. **Install OLM in your cluster:**

   ```sh
   operator-sdk olm install
   ```

2. **Deploy the CatalogSource:**

   ```sh
   kubectl create ns test1
   kubectl create -f catalogSource.yaml
   kubectl get packagemanifest -A | grep GRC
   ```

   Example output:

   ```
   example-operator                           GRC mock operators    2m
   deprecation-operator                       GRC mock operators    2m
   ```

3. **Install the OperatorGroup and Subscription, modifying the files as needed for the operator you intend to deploy:**

   ```sh
   kubectl create -f deploy/operatorgroup.yaml
   yq '.spec.name = "<operator-name>"' deploy/subscription.yaml | kubectl create -f -
   ```

4. **Verify the CSV status:**

   ```sh
   kubectl get csv -n test1
   ```

   Example output:

   ```
   NAME                          DISPLAY                VERSION   REPLACES   PHASE
   deprecation-operator.v0.0.1   deprecation-operator   0.0.1                Succeeded
   ```
