# Min just version 1.46.0 https://github.com/casey/just/issues/2290
export repo_organization := env("GITHUB_REPOSITORY_OWNER", "ublue-os")
export base_image_org := env("BASE_IMAGE_ORG", "quay.io/fedora-ostree-desktops")
export base_image_name := env("BASE_IMAGE_NAME", "kinoite")

stable_version := "44"
latest_version := "44"
testing_version := "44"

images := '(
    [aurora]=aurora
    [aurora-dx]=aurora-dx
)'

flavors := '(
    [main]=main
    [nvidia-open]=nvidia-open
)'

tags := '(
    [stable]=stable
    [latest]=latest
    [testing]=testing
)'

# Build Containers
chunkah := shell("yq -r \".images[] | select(.name == \\\"chunkah\\\") | \\\"\\\\(.image)@\\\\(.digest)\\\"\" image-versions.yml")
common := shell("yq -r \".images[] | select(.name == \\\"common\\\") | \\\"\\\\(.image)@\\\\(.digest)\\\"\" image-versions.yml")
brew := shell("yq -r \".images[] | select(.name == \\\"brew\\\") | \\\"\\\\(.image)@\\\\(.digest)\\\"\" image-versions.yml")

export SUDO_DISPLAY := if `if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then echo true; fi` == "true" { "true" } else { "false" }
export SUDOIF := if `id -u` == "0" { "" } else { "sudo" }
export PODMAN := "podman"
export BUILDAH := "buildah"
just := just_executable()

# Define a retry function for use in recipes
retry_function := '
retry() {
    if [[ "${#}" -lt 3 ]]; then
        echo "retry usage: <number of tries> <time between retries> <command> ..."
        return 1
    fi
    tries="${1}"
    sleep="${2}"
    shift 2
    for i in $(seq 1 ${tries}); do
        if [[ ${i} -gt 1 ]]; then
            # echo "[+] Command failed. Waiting for ${sleep} seconds"
            sleep ${sleep}
        fi
        # echo "[+] Running (try: ${i}): ${@}"
        "${@}" && r=0 && break || r=$?
    done
    return $r
}
'

[private]
default:
    @{{ just }} --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      {{ just }} --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      {{ just }} --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -eoux pipefail
    rm -f changelog.md
    rm -f output.env
    rm -rf sbom_out
    rm -f /tmp/aurora*-tags.json

# Check if valid combo
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[private]
validate $image $tag $flavor:
    #!/usr/bin/env bash
    set -eou pipefail

    declare -A images={{ images }}
    declare -A tags={{ tags }}
    declare -A flavors={{ flavors }}

    checkimage="${images[${image}]-}"
    checktag="${tags[${tag}]-}"
    checkflavor="${flavors[${flavor}]-}"

    # Validity Checks
    if [[ -z "$checkimage" ]]; then
        echo "Invalid Image..."
        exit 1
    fi
    if [[ -z "$checktag" ]]; then
        echo "Invalid tag..."
        exit 1
    fi
    if [[ -z "$checkflavor" ]]; then
        echo "Invalid flavor..."
        exit 1
    fi

# Build Image
[arg("flavor", long="flavor", short="f")]
[arg("ghcr", long="ghcr", value="true")]
[arg("image", long="image", short="i")]
[arg("kernel_pin", long="kernel-pin")]
[arg("rechunk", long="rechunk", value="true")]
[arg("tag", long="tag", short="t")]
[group('Image')]
build $image="aurora" $tag="latest" $flavor="main" $rechunk="false" $ghcr="false" $kernel_pin="":
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"

    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")
    akmods_flavor=$({{ just }} akmods_flavor --tag "${tag}")
    fedora_version=$({{ just }} fedora_version --image "${image}" --tag "${tag}" --flavor "${flavor}")

    # Verify Base Image with cosign
    {{ just }} verify-container quay.io-fedora-ostree-desktops.pub ${base_image_org}/${base_image_name}:${fedora_version}

    # Here we pin our kernels to workaround regressions!
    # skopeo list-tags docker://ghcr.io/ublue-os/akmods | jq -r '.Tags | map(select(contains("coreos-stable-44")))'

    ARCH=$(arch)
    if [[ -z "${kernel_pin:-}" ]]; then
      case "${tag}" in
              stable)
                  if [[ "${ARCH}" == "x86_64" ]]; then
                      # <Here is a link why we have it pinned>
                      kernel_pin=""
                  elif [[ "${ARCH}" == "aarch64" ]]; then
                      kernel_pin=""
                  fi
                  ;;
              latest)
                  if [[ "${ARCH}" == "x86_64" ]]; then
                      kernel_pin=""
                  elif [[ "${ARCH}" == "aarch64" ]]; then
                      kernel_pin=""
                  fi
                  ;;
              testing)
                  if [[ "${ARCH}" == "x86_64" ]]; then
                      kernel_pin=""
                  elif [[ "${ARCH}" == "aarch64" ]]; then
                      kernel_pin=""
                  fi
                  ;;
      esac
    fi

    if [[ -z "${kernel_pin:-}" ]]; then
        kernel_release=$(skopeo inspect --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${akmods_flavor}"-"${fedora_version}" | jq -r '.Labels["ostree.linux"]')
    else
        kernel_release="${kernel_pin}"
    fi

    # Verify Containers with Cosign
    {{ just }} verify-container cosign.pub "ghcr.io/ublue-os/akmods:${akmods_flavor}-${fedora_version}-${kernel_release}"
    if [[ "${akmods_flavor}" =~ coreos ]]; then
        {{ just }} verify-container cosign.pub "ghcr.io/ublue-os/akmods-zfs:${akmods_flavor}-${fedora_version}-${kernel_release}"
    fi
    if [[ "${flavor}" =~ nvidia-open ]]; then
        {{ just }} verify-container cosign.pub "ghcr.io/ublue-os/akmods-nvidia-open:${akmods_flavor}-${fedora_version}-${kernel_release}"
    fi

    cosign verify \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com \
      --certificate-identity-regexp="github.com/get-aurora-dev/common/.github/workflows/*" \
      "{{ common }}"

    cosign verify \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com \
      --certificate-identity-regexp="github.com/coreos/chunkah/.github/workflows/*" \
      "{{ chunkah }}"

    {{ just }} verify-container cosign.pub "{{ brew }}"

    # Get Version
    TIMESTAMP="$(date +%Y%m%d)"
    if [[ "${tag}" =~ stable ]]; then
        ver="${fedora_version}.${TIMESTAMP}"
    else
        ver="${tag}-${fedora_version}.${TIMESTAMP}"
    fi

    POINT=$({{ just }} generate-point --image "${image}" --tag "${tag}" --flavor "${flavor}")
    ver="${ver}.$POINT"

    # Build Arguments
    BUILD_ARGS=()
    # Target
    if [[ "${image}" =~ dx ]]; then
           BUILD_ARGS+=("--build-arg" "IMAGE_FLAVOR=dx")
           target="dx"
    fi
    BUILD_ARGS+=("--build-arg" "AKMODS_FLAVOR=${akmods_flavor}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE_ORG=${base_image_org}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE_NAME=${base_image_name}")
    BUILD_ARGS+=("--build-arg" "FEDORA_MAJOR_VERSION=${fedora_version}")
    BUILD_ARGS+=("--build-arg" "COMMON={{ common }}")
    BUILD_ARGS+=("--build-arg" "BREW={{ brew }}")
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image_name}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR={{ repo_organization }}")
    BUILD_ARGS+=("--build-arg" "KERNEL=${kernel_release}")
    BUILD_ARGS+=("--build-arg" "VERSION=${ver}")
    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    else
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=deadbeef")
    fi
    BUILD_ARGS+=("--build-arg" "UBLUE_IMAGE_TAG=${tag}")

    # Labels
    LABELS=()
    LABELS+=("--label" "containers.bootc=1")
    LABELS+=("--label" "io.artifacthub.package.deprecated=false")
    LABELS+=("--label" "io.artifacthub.package.keywords=bootc,fedora,aurora,ublue,universal-blue,kde,linux")
    LABELS+=("--label" "io.artifacthub.package.logo-url=https://avatars.githubusercontent.com/u/120078124?s=200&v=4")
    LABELS+=("--label" "io.artifacthub.package.maintainers=[{\"name\": \"NiHaiden\", \"email\": \"me@nhaiden.io\"}]")
    LABELS+=("--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/ublue-os/aurora/refs/heads/main/README.md")
    LABELS+=("--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)")
    LABELS+=("--label" "org.opencontainers.image.description=The ultimate productivity workstation")
    LABELS+=("--label" "org.opencontainers.image.documentation=https://docs.getaurora.dev")
    LABELS+=("--label" "org.opencontainers.image.source=https://raw.githubusercontent.com/ublue-os/aurora/refs/heads/main/Containerfile.in")
    LABELS+=("--label" "org.opencontainers.image.title=${image_name}")
    LABELS+=("--label" "org.opencontainers.image.url=https://getaurora.dev")
    LABELS+=("--label" "org.opencontainers.image.vendor={{ repo_organization }}")
    LABELS+=("--label" "org.opencontainers.image.version=${ver}")
    if [[ -z "$(git status -s)" ]]; then
        LABELS+=("--label" "org.opencontainers.image.revision=$(git rev-parse HEAD)")
    else
        LABELS+=("--label" "org.opencontainers.image.revision=deadbeef")
    fi
    LABELS+=("--label" "ostree.linux=${kernel_release}")

    case "${akmods_flavor}" in
    "coreos-stable") BUILD_ARGS+=("--cpp-flag=-DZFS") ;;
    esac

    if [[ "${image_name}" =~ nvidia ]]; then
        BUILD_ARGS+=("--cpp-flag=-DNVIDIA")
    fi

    PODMAN_BUILD_ARGS=("${BUILD_ARGS[@]}" "${LABELS[@]}" --tag "${image_name}:${tag}" --file Containerfile.in)

    # Bump retries to minimize network flakes
    PODMAN_BUILD_ARGS+=("--retry=5" "--retry-delay=60s")

    # So we always have the newest images when building locally
    if [[ "${ghcr}" == "false" ]]; then
      PODMAN_BUILD_ARGS+=("--pull=newer")
    fi

    # Add GitHub token secret if available (for CI/CD)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "Adding GitHub token as build secret"
        PODMAN_BUILD_ARGS+=(--secret "id=GITHUB_TOKEN,env=GITHUB_TOKEN")
    else
        echo "No GitHub token found - build may hit rate limit"
    fi

    ${BUILDAH} build "${PODMAN_BUILD_ARGS[@]}" .
    echo "::endgroup::"

# Build Image and Rechunk
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("kernel_pin", long="kernel-pin")]
[arg("tag", long="tag", short="t")]
[group('Image')]
build-rechunk $image="aurora" $tag="latest" $flavor="main" kernel_pin="": (build image tag flavor kernel_pin) (rechunk image tag flavor)

# Rechunk Image
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Image')]
rechunk $image="aurora" $tag="latest" $flavor="main":
    #!/usr/bin/env bash

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    export CHUNKAH_CONFIG_STR=$(${PODMAN} inspect "${image_name}:${tag}")

    set -eoux pipefail

    ${PODMAN} run --rm --mount=type=image,src="${image_name}:${tag}",target=/chunkah \
    -e CHUNKAH_CONFIG_STR "{{ chunkah }}" \
    build \
    --verbose \
    --compressed \
    --max-layers 128 \
    --prune /sysroot/ \
    --label ostree.commit- --label ostree.final-diffid- \
    --tag "${image_name}:${tag}" | ${PODMAN} load

# build-chunked-oci
[arg("flavor", long="flavor", short="f")]
[arg("ghcr", long="ghcr", value="true")]
[arg("image", long="image", short="i")]
[arg("previous_build", long="previous-build", value="true")]
[arg("tag", long="tag", short="t")]
[group('Image')]
ostree-rechunk $image="aurora" $tag="latest" $flavor="main" $ghcr="false" $previous_build="false":
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")
    fedora_version=$({{ just }} fedora_version --image "${image}" --tag "${tag}" --flavor "${flavor}")

    if [[ "{{ ghcr }}" == "false" ]]; then
      {{ just }} load-rootful --image "${image}" --tag "${tag}" --flavor "${flavor}"
    fi

    # TODO: Redo everything here with --previous-build in rpm-ostree 2026.1+
    # so we don't have to pull an old image + rename it
    if [[ "${previous_build}" == "true" ]]; then
      PREVIOUS_IMAGE=ghcr.io/{{ repo_organization }}/"${image_name}":"${tag}"

      # https://github.com/coreos/rpm-ostree/blob/7e2f2065a4aa4d5965b4537bb7d74e0b2898650e/rust/src/compose.rs#L522-L529
      if skopeo inspect docker://"${PREVIOUS_IMAGE}" | jq -e '.LayersData[1:] | all(.Annotations?["ostree.components"]?)'; then
        ${SUDOIF} ${PODMAN} pull ${PREVIOUS_IMAGE}
      else
        echo "${PREVIOUS_IMAGE} doesn't exist. Making a fresh layer Plan instead."
      fi
    fi

    if [[ "${ghcr}" == "true" ]]; then
      CHUNKED_IMAGE="${image_name}:${tag}"
        if [[ "${previous_build}" == "true" ]]; then
          CHUNKED_IMAGE="${PREVIOUS_IMAGE}"
        fi
    else
      # keep the original unrechunked image for local builds
      CHUNKED_IMAGE="${image_name}:${tag}-chunked"
    fi

    # 96 layers, conservative default, same what ci-test is using
    # one layer is secretly being added for the ostree export
    # 499 is podman run limit
    # 128 is docker pull limit
    ${SUDOIF} ${PODMAN} run --rm \
        --privileged \
        -v "/var/lib/containers:/var/lib/containers" \
        --entrypoint /usr/bin/rpm-ostree \
        "${base_image_org}/${base_image_name}:${fedora_version}" \
        compose build-chunked-oci \
        --max-layers 127 \
        --format-version=2 \
        --bootc \
        --from "localhost/${image_name}:${tag}" \
        --output containers-storage:${CHUNKED_IMAGE}

        # rename the image to localhost
        if [[ "${ghcr}" == "true" && "${previous_build}" == "true" ]]; then
          ${SUDOIF} ${PODMAN} tag ${CHUNKED_IMAGE} "${image_name}:${tag}"
          ${SUDOIF} ${PODMAN} image rm -f ${CHUNKED_IMAGE}
        fi

# For Privileged operations
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Image')]
load-rootful $image="aurora" $tag="latest" $flavor="main":
    #!/usr/bin/env bash
    set -oux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    if [[ ! "$(id -u)" == 0 ]]; then
      ID=$(${PODMAN} images --filter reference="${image_name}:${tag}" --format "'{{ '{{.ID}}' }}'")
      if [[ -z "$ID" ]]; then
          {{ just }} build "$image" "$tag" "$flavor"
      fi
      ${PODMAN} image scp "${image_name}:${tag}" root@localhost::
    fi

# Generate OCI Archive for PR Testing
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Utility')]
export-oci $image="aurora" $tag="latest" $flavor="main":
    #!/usr/bin/env bash
    set -oux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    ARCHIVE_NAME="${image_name}"-"$(arch)".oci

    ${PODMAN} push --compression-format=zstd --compression-level=3 "${image_name}:${tag}" oci-archive:"${ARCHIVE_NAME}"

# Run Container
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Image')]
run $image="aurora" $tag="latest" $flavor="main":
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")
    # Check if image exists
    ID=$(${PODMAN} images --filter reference="${image_name}:${tag}" --format "'{{ '{{.ID}}' }}'")
    if [[ -z "$ID" ]]; then
        {{ just }} build "$image" "$tag" "$flavor"
    fi

    # Run Container
    ${PODMAN} run -it --rm "${image_name}:${tag}" bash

# Test Changelogs
[group('Changelogs')]
changelogs branch="stable" handwritten="":
    #!/usr/bin/env bash
    set -eou pipefail
    python3 ./.github/changelogs.py "{{ branch }}" ./output.env ./changelog.md --workdir . --handwritten "{{ handwritten }}"

# Verify Container with Cosign
[group('Utility')]
verify-container key="" container="":
    #!/usr/bin/env bash
    set -eou pipefail

    # Get Cosign if Needed
    if [[ ! $(command -v cosign) ]]; then
        COSIGN_CONTAINER_ID=$(${SUDOIF} ${PODMAN} create cgr.dev/chainguard/cosign:latest bash)
        ${SUDOIF} ${PODMAN} cp "${COSIGN_CONTAINER_ID}":/usr/bin/cosign /usr/local/bin/cosign
        ${SUDOIF} ${PODMAN} rm -f "${COSIGN_CONTAINER_ID}"
    fi

    # Verify Cosign Image Signatures if needed
    if [[ -n "${COSIGN_CONTAINER_ID:-}" ]]; then
        if ! cosign verify --certificate-oidc-issuer=https://token.actions.githubusercontent.com --certificate-identity=https://github.com/chainguard-images/images/.github/workflows/release.yaml@refs/heads/main cgr.dev/chainguard/cosign >/dev/null; then
            echo "NOTICE: Failed to verify cosign image signatures."
            exit 1
        fi
    fi

    # Verify Container using cosign public key
    if ! cosign verify --key "{{ key }}" "{{ container }}" >/dev/null; then
        echo "NOTICE: Verification failed. Please ensure your public key is correct."
        exit 1
    fi

# Secureboot Check
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Utility')]
secureboot $image="aurora" $tag="latest" $flavor="main":
    #!/usr/bin/env bash
    set -eou pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    # Get the vmlinuz to check
    kernel_release=$(${PODMAN} inspect "${image_name}":"${tag}" | jq -r '.[].Config.Labels["ostree.linux"]')
    TMP=$(${PODMAN} create "${image_name}":"${tag}" bash)
    ${PODMAN} cp "$TMP":/usr/lib/modules/"${kernel_release}"/vmlinuz /tmp/vmlinuz
    ${PODMAN} rm "$TMP"

    # Get the Public Certificates
    curl --retry 3 -Lo /tmp/kernel-sign.der https://github.com/ublue-os/akmods/raw/main/certs/public_key.der
    curl --retry 3 -Lo /tmp/akmods.der https://github.com/ublue-os/akmods/raw/main/certs/public_key_2.der
    openssl x509 -in /tmp/kernel-sign.der -out /tmp/kernel-sign.crt
    openssl x509 -in /tmp/akmods.der -out /tmp/akmods.crt

    # Make sure we have sbverify
    CMD="$(command -v sbverify || true)"
    if [[ -z "${CMD:-}" ]]; then
        temp_name="sbverify-${RANDOM}"
        ${PODMAN} run -dt \
            --entrypoint /bin/sh \
            --volume /tmp/vmlinuz:/tmp/vmlinuz:z \
            --volume /tmp/kernel-sign.crt:/tmp/kernel-sign.crt:z \
            --volume /tmp/akmods.crt:/tmp/akmods.crt:z \
            --name ${temp_name} \
            docker.io/library/alpine:edge
        ${PODMAN} exec ${temp_name} apk add sbsigntool
        CMD="${PODMAN} exec ${temp_name} /usr/bin/sbverify"
    fi

    # Confirm that Signatures Are Good
    $CMD --list /tmp/vmlinuz
    returncode=0
    if ! $CMD --cert /tmp/kernel-sign.crt /tmp/vmlinuz || ! $CMD --cert /tmp/akmods.crt /tmp/vmlinuz; then
        echo "Secureboot Signature Failed...."
        returncode=1
    fi
    if [[ -n "${temp_name:-}" ]]; then
        ${PODMAN} rm -f "${temp_name}"
    fi
    exit "$returncode"

# Get Fedora Version of an image
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[private]
fedora_version image="aurora" tag="latest" flavor="main":
    #!/usr/bin/env bash
    set -eou pipefail

    {{ just }} validate --image {{ image }} --tag {{ tag }} --flavor {{ flavor }}

    # Determine Version
    if [[ "{{ tag }}" =~ stable ]]; then
        VERSION="{{ stable_version }}"
    elif [[ "{{ tag }}" =~ testing ]]; then
        VERSION="{{ testing_version }}"
    else
        VERSION="{{ latest_version }}"
    fi

    echo "${VERSION}"

[arg("tag", long="tag", short="t")]
[private]
akmods_flavor tag="latest":
    #!/usr/bin/env bash
    set -eou pipefail

    if [[ "{{ tag }}" =~ stable ]]; then
        akmods_flavor="coreos-stable"
    elif [[ "{{ tag }}" =~ testing ]]; then
        akmods_flavor="main"
    else
        akmods_flavor="main"
    fi

    echo "${akmods_flavor}"

# Image Name
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[private]
image_name image="aurora" tag="latest" flavor="main":
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image {{ image }} --tag {{ tag }} --flavor {{ flavor }}
    if [[ "{{ flavor }}" =~ main ]]; then
        image_name={{ image }}
    else
        image_name="{{ image }}-{{ flavor }}"
    fi

    echo "${image_name}"

# Generate Tags
[arg("flavor", long="flavor", short="f")]
[arg("ghcr", long="ghcr", value="true")]
[arg("github_event", long="github-event")]
[arg("github_number", long="github-number")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[arg("version", long="version")]
[group('Utility')]
generate-build-tags $image="aurora" $tag="latest" $flavor="main" $ghcr="false" $version="" $github_event="" $github_number="":
    #!/usr/bin/env bash
    set -eoux pipefail

    FEDORA_VERSION=$({{ just }} fedora_version --image "${image}" --tag "${tag}" --flavor "${flavor}")
    IMAGE_NAME=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    TIMESTAMP="$(date +%Y%m%d)"
    version="${FEDORA_VERSION}.${TIMESTAMP}"

    BUILD_TAGS=()
    COMMIT_TAGS=()

    # Commit Tags
    github_number="${github_number}"
    SHA_SHORT="$(git rev-parse --short HEAD)"
    if [[ "${ghcr}" == "true" ]]; then
        COMMIT_TAGS+=(pr-${github_number:-}-${tag}-${version})
        COMMIT_TAGS+=(${SHA_SHORT}-${tag}-${version})
    fi

    POINT=$({{ just }} generate-point --image "${image}" --tag "${tag}" --flavor "${flavor}")

    # These are always used regardless of the stream
    COMMON_TAGS=()
    COMMON_TAGS+=("${tag}")
    COMMON_TAGS+=("${tag}-${version}")
    COMMON_TAGS+=("${tag}-${version:3}")
    COMMON_TAGS+=("${tag}-${version}.${POINT}")
    COMMON_TAGS+=("${tag}-${version:3}.${POINT}")

    BUILD_TAGS=("${COMMON_TAGS[@]}" "${BUILD_TAGS[@]}")

    # No special handling here for testing for now
    if [[ "{{ tag }}" == stable ]]; then
      # Legacy Compatibility Tag so stable-daily points to stable, do not remove this
      # TODO: Move this to :latest after the ZFS removal to get daily updates again
      BUILD_TAGS+=("{{ tag }}-daily")
      BUILD_TAGS+=("${version}")
      BUILD_TAGS+=("{{ tag }}-daily-${version}")
      BUILD_TAGS+=("{{ tag }}-daily-${version:3}")
      BUILD_TAGS+=("{{ tag }}-daily-${version}.${POINT}")
      BUILD_TAGS+=("{{ tag }}-daily-${version:3}.${POINT}")
    elif [[ "{{ tag }}" == latest ]]; then
      # We only want :$FEDORA_VERSION to point to :latest
      BUILD_TAGS+=("{{ tag }}-${FEDORA_VERSION}")
      BUILD_TAGS+=("${FEDORA_VERSION}-${version}")
      BUILD_TAGS+=("${FEDORA_VERSION}-${version:3}")
      BUILD_TAGS+=("${FEDORA_VERSION}-${version}.${POINT}")
      BUILD_TAGS+=("${FEDORA_VERSION}-${version:3}.${POINT}")
    fi

    github_event="${github_event}"

    if [[ "${github_event}" == "pull_request" ]]; then
        alias_tags=("${COMMIT_TAGS[@]}")
    else
        alias_tags=("${BUILD_TAGS[@]}")
    fi

    echo "${alias_tags[*]}"

# Get Index Point for multiple daily images
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[private]
generate-point $image="aurora" $tag="latest" $flavor="main":
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    IMAGE_NAME=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")
    TIMESTAMP="$(date +%Y%m%d)"

    tags="/tmp/${IMAGE_NAME}-tags.json"

    if [[ ! -f ${tags} ]]; then
      skopeo list-tags docker://ghcr.io/{{ repo_organization }}/${IMAGE_NAME} > "${tags}"
    fi

    if [[ $(jq --arg tag "${tag}" --arg timestamp "${TIMESTAMP}" 'any(.Tags[]; contains($tag + "-" + $timestamp))' < "${tags}") == "true" ]]; then

      # our image already exists, so find the highest POINT
      POINT=$(jq -r --arg tag "${tag}" --arg timestamp "${TIMESTAMP}" \
        '($tag + "-" + $timestamp) as $base | [ .Tags[] | select(startswith($base + ".")) ] | sort_by(split(".")[-1]
        | tonumber)
        |.[-1] | if . == null then "1" else split(".")[-1] end' < "${tags}")

      ((POINT++))

    else
      # there is no image that exists for that day yet
      POINT=1
    fi

    echo "${POINT}"

# Tag Images
[arg("default_tag", long="default-tag")]
[arg("image", long="image", short="i")]
[arg("tags", long="tags")]
[group('Utility')]
tag-images $image="" $default_tag="" $tags="":
    #!/usr/bin/env bash
    set -eoux pipefail

    # Get Image, and untag
    IMAGE=$(${PODMAN} inspect "${image}:${default_tag}" | jq -r .[].Id)
    ${PODMAN} untag localhost/"${image}:${default_tag}"

    # Tag Image
    # Do not quote this, we want word splitting here
    for tag in ${tags}; do
        ${PODMAN} tag $IMAGE ${image}:${tag}
    done

    # Show Images
    ${PODMAN} images

# Extract Container and generate SBOM
[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Utility')]
gen-sbom $image="aurora" $tag="latest" $flavor="main" $syft_cmd="syft":
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    OUT_DIR="sbom_out/${image_name}"
    mkdir -p "${OUT_DIR}"

    # We have to do it this stupid way because we are OOMing on github runners
    # https://github.com/anchore/syft/issues/3800
    ${PODMAN} container create --replace --name ${image_name} "${image_name}:${tag}"

    ROOTFS="${OUT_DIR}/rootfs"
    mkdir -p "${ROOTFS}"

    ${PODMAN} export ${image_name} | tar -C "${ROOTFS}" -xf -
    ${PODMAN} container rm ${image_name}

    SBOM="${OUT_DIR}/sbom.json"

    ${syft_cmd} --source-name "${image_name}:${tag}" "${OUT_DIR}" -o syft-json=${SBOM}
    du -sh "${SBOM}"

    rm -rf "${ROOTFS}"

# DNF CI package cache
[arg("flavor", long="flavor", short="f")]
[arg("ghcr", long="ghcr", value="true")]
[arg("github_event", long="github-event")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Utility')]
[private]
setup-cache $image="aurora" $tag="latest" $flavor="main" $ghcr="false" $github_event="":
    #!/usr/bin/env bash
    set -eou pipefail

    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    fedora_version=$({{ just }} fedora_version --image "${image}" --tag "${tag}" --flavor "${flavor}")

    ALLOW_CACHE_WRITE="false"

    BLESSED_IMAGE=aurora-dx

    if [[ "${image_name}" == "${BLESSED_IMAGE}" ]] && \
       [[ "${ghcr}" == "true" ]] && \
       [[ "${github_event}" == "workflow_dispatch" || "${github_event}" == "schedule" ]]; then
        ALLOW_CACHE_WRITE="true"
    fi

    CACHE_NAME="${BLESSED_IMAGE}-${fedora_version}"

    echo "${CACHE_NAME}" "${ALLOW_CACHE_WRITE}"

[arg("flavor", long="flavor", short="f")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[private]
bootc $image="aurora" $tag="latest" $flavor="main" *ARGS:
    #!/usr/bin/env bash
    set -eoux pipefail

    {{ just }} validate --image "${image}" --tag "${tag}" --flavor "${flavor}"
    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    BOOTC_INSTALL_OPTIONS=()
    BOOTC_INSTALL_OPTIONS+=("-v" "/var/lib/containers:/var/lib/containers" "-v" "/etc/containers:/etc/containers")

    if [[ -d /sys/fs/selinux ]]; then
      BOOTC_INSTALL_OPTIONS+=("-v" "/sys/fs/selinux:/sys/fs/selinux" "--security-opt" "label=type:unconfined_t")
    fi

    ${PODMAN} run \
        --rm --privileged --pid=host \
        -it \
        "${BOOTC_INSTALL_OPTIONS[@]}" \
        -v /dev:/dev \
        -v "${BUILD_BASE_DIR:-.}:/data" \
        "${image_name}:${tag}" bootc {{ ARGS }}

# Create bootable image
[arg("backend", long="backend")]
[arg("flavor", long="flavor", short="f")]
[arg("ghcr", long="ghcr", value="true")]
[arg("image", long="image", short="i")]
[arg("tag", long="tag", short="t")]
[group('Utility')]
disk-image $image="aurora" $tag="latest" $flavor="main" $ghcr="false" $backend="ostree":
    #!/usr/bin/env bash
    set -eoux pipefail

    # this is enough for base aurora to make it more likely to run in CI
    if [[ "${ghcr}" == "true" ]]; then
      # absurd size so it will always be enough for the image
      IMG_SIZE=35G
    else
      # Should at least be enough to rebase and install couple applications
      IMG_SIZE=40G
    fi

    BYTES_IMAGE_SIZE=$(numfmt --from=iec ${IMG_SIZE})

    if [ ! -e "${BUILD_BASE_DIR:-.}/bootable.img" ]; then
      FREE_SPACE=$(findmnt -bno AVAIL -T "${BUILD_BASE_DIR:-.}")
      if [ "${FREE_SPACE}" -gt "${BYTES_IMAGE_SIZE}" ]; then
        fallocate -l "${BYTES_IMAGE_SIZE}" "${BUILD_BASE_DIR:-.}/bootable.img"
      else
        echo "not enough disk space available"
        exit 1
      fi
    fi

    BOOTC_INSTALL_ARGS=()
    BOOTC_INSTALL_ARGS+=("--generic-image"  "--via-loopback" "/data/bootable.img" "--wipe")

    if [[ "${backend}" == "ostree" ]]; then
      BOOTC_INSTALL_ARGS+=("--bootloader grub")
    else
      BOOTC_INSTALL_ARGS+=("--bootloader systemd" "--composefs-backend")
    fi

    {{ just }} bootc "${image}" "${tag}" "${flavor}" install to-disk "${BOOTC_INSTALL_ARGS[@]}"

# FIXME: Please consider using podman push in the future for signing as well instead of temporary tag + cosign
# See: https://github.com/ublue-os/aurora/pull/2199
# Once https://github.com/containers/podman/issues/27796 is resolved

# Push Image to Registry
[arg("flavor", long="flavor", short="f")]
[arg("ghcr", long="ghcr", value="true")]
[arg("image", long="image", short="i")]
[arg("registry", long="registry")]
[arg("tag", long="tag", short="t")]
[arg("temp_push", long="temp-push", value="true")]
[arg("temp_push_tag", long="temp-push-tag")]
[group('Utility')]
push-image $image="aurora" $tag="latest" $flavor="main" $ghcr="false" $registry="" $temp_push="false" $temp_push_tag="":
    #!/usr/bin/env bash
    set -eoux pipefail

    PUSH_CMD_ARGS=()
    PUSH_CMD_ARGS+=("--digestfile=/tmp/digestfile")
    PUSH_CMD_ARGS+=("--compression-format=zstd")
    PUSH_CMD_ARGS+=("--compression-level=3")
    PUSH_CMD_ARGS+=("--retry-delay=30s")
    PUSH_CMD_ARGS+=("--retry=5")

    PUSH_CMD=""${PODMAN}" push "${PUSH_CMD_ARGS[@]}""

    image_name=$({{ just }} image_name --image "${image}" --tag "${tag}" --flavor "${flavor}")

    alias_tags=$({{ just }} generate-build-tags --image "${image}" --tag "${tag}" --flavor "${flavor}")

    if [[ "${ghcr}" == "true" && -n "${registry}" ]]; then

      if [[ "${temp_push}" == "false" ]]; then
        for tag in ${alias_tags}; do
          ${PUSH_CMD} ${image_name}:${tag} ${registry}/${image_name}:${tag}
          # We need to push twice to workaround https://github.com/containers/podman/issues/27796
          ${PUSH_CMD} ${image_name}:${tag} ${registry}/${image_name}:${tag}
          cat /tmp/digestfile
        done

      elif [[ "${temp_push}" == "true" ]]; then
        ${PUSH_CMD} ${image_name}:${tag} ${registry}/${image_name}:${temp_push_tag}-${tag}
        # We need to push twice to workaround https://github.com/containers/podman/issues/27796
        # If we don't do this then the digest changes and we are only signing this specific tag
        ${PUSH_CMD} ${image_name}:${tag} ${registry}/${image_name}:${temp_push_tag}-${tag}
      fi

    else
      echo "This is intended to be run in ghcr only."
      exit 1
    fi

# Login to Container Registry
[group('Utility')]
login-registry bin="" registry="":
    #!/usr/bin/env bash
    set -euxo pipefail

    {{ retry_function }}

    retry 5 60 echo "${GITHUB_TOKEN}" | "{{ bin }}" login "{{ registry }}" -u "${GITHUB_ACTOR}" --password-stdin

# # Examples:
#   > just retag-nvidia-on-ghcr stable stable-41.20250126.3 0
#   > just retag-nvidia-on-ghcr latest latest-41.20250228.1 0
#
# working_tag: The tag of the most recent known good image (e.g., latest.20250126.3)
# stream:      One of latest, stable or testing
# dry_run:     Only print the skopeo commands instead of running them
#
# First generate a PAT with package write access (https://github.com/settings/tokens)
# and set $GITHUB_USERNAME and $GITHUB_PAT environment variables

# Retag images on GHCR
[group('Admin')]
retag-nvidia-on-ghcr working_tag="" stream="" dry_run="1":
    #!/usr/bin/env bash
    set -euxo pipefail
    skopeo="echo === skopeo"
    if [[ "{{ dry_run }}" -ne 1 ]]; then
        echo "$GITHUB_PAT" | podman login -u $GITHUB_USERNAME --password-stdin ghcr.io
        skopeo="skopeo"
    fi
    for image in aurora-nvidia-open aurora-dx-nvidia-open; do
      $skopeo copy docker://ghcr.io/ublue-os/${image}:{{ working_tag }} docker://ghcr.io/ublue-os/${image}:{{ stream }}
    done
