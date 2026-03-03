#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

# determine a version string (prefer git tags, fall back to pubspec.yaml)
VERSION=""
if command -v git >/dev/null 2>&1; then
    VERSION=$(git describe --tags --dirty --always 2>/dev/null || true)
fi
if [ -z "${VERSION}" ]; then
    if [ -f app/xiaoheifs_app/pubspec.yaml ]; then
        VERSION=$(grep '^version:' app/xiaoheifs_app/pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
    fi
fi
VERSION=${VERSION:-local}

BUILD_OPTION="${1:-}"
IMAGE_REPO="${2:-xiaoheifs-backend}"

if [[ -z "${BUILD_OPTION}" ]]; then
    echo "Select build option:"
    echo "  1) latest (debian)"
    echo "  2) alpine"
    echo "  0) all"
    read -r -p "Enter choice [1/2/0]: " CHOICE
    case "${CHOICE}" in
        1) BUILD_OPTION="latest" ;;
        2) BUILD_OPTION="alpine" ;;
        0) BUILD_OPTION="all" ;;
        *)
            echo "Invalid choice: ${CHOICE}"
            exit 1
            ;;
    esac
fi

# backward compatible: first arg as image name
if [[ "${BUILD_OPTION}" != "latest" && "${BUILD_OPTION}" != "alpine" && "${BUILD_OPTION}" != "all" ]]; then
    IMAGE_REPO="${BUILD_OPTION}"
    BUILD_OPTION="latest"
fi

# tags are controlled by build option
IMAGE_REPO="${IMAGE_REPO%%:*}"

build_image() {
    local dockerfile="$1"
    local tag="$2"
    local image="${IMAGE_REPO}:${tag}"
    docker build -f "${dockerfile}" --build-arg VERSION="${VERSION}" -t "${image}" .
    echo "Image built: ${image} (version ${VERSION})"
}

case "${BUILD_OPTION}" in
    latest)
        build_image "docker/build/Dockerfile" "latest"
        ;;
    alpine)
        build_image "docker/build/Dockerfile.alpine" "alpine"
        ;;
    all)
        build_image "docker/build/Dockerfile" "latest"
        build_image "docker/build/Dockerfile.alpine" "alpine"
        ;;
esac
