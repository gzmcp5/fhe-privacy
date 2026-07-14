#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
BUILD_ROOT=${OPENFHE_BUILD_ROOT:-"${ROOT_DIR}/build/openfhe-wheel"}
PACKAGER_DIR="${BUILD_ROOT}/openfhe-python-packager"
OUTPUT_DIR="${ROOT_DIR}/vendor/wheels"

OPENFHE_CORE_COMMIT=1306d14f8c26bb6150d3e6ad54f28dfe1007689e
OPENFHE_PYTHON_COMMIT=4f13e2c3a7e35f73f4816904dabd3a3db47b6e51
PACKAGER_COMMIT=099b8bddd045e941fb8a91f48214da800d9bc27c

PYTHON=${PYTHON:-python3.13}
PYTHON_REAL=$(${PYTHON} -c 'import sys; print(sys.executable)')
PYTHON_VERSION=$(${PYTHON_REAL} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
if [[ ${PYTHON_VERSION} != "3.13" ]]; then
    echo "OpenFHE wheel build requires Python 3.13, found ${PYTHON_VERSION}" >&2
    exit 1
fi

case "$(uname -s):$(uname -m)" in
    Linux:x86_64)
        OS_NAME=Ubuntu
        OS_RELEASE=24.04
        PLATFORM_TAG=linux_x86_64
        ;;
    Darwin:arm64)
        OS_NAME=macOS
        OS_RELEASE=14.0
        PLATFORM_TAG=macosx_14_0_arm64
        export MACOSX_DEPLOYMENT_TARGET=14.0
        ;;
    *)
        echo "Unsupported OpenFHE wheel target: $(uname -s) $(uname -m)" >&2
        exit 1
        ;;
esac

rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}" "${OUTPUT_DIR}" "${BUILD_ROOT}/python-bin"
ln -s "${PYTHON_REAL}" "${BUILD_ROOT}/python-bin/python3"

git clone https://github.com/openfheorg/openfhe-python-packager.git "${PACKAGER_DIR}"
git -C "${PACKAGER_DIR}" checkout --detach "${PACKAGER_COMMIT}"

mkdir -p "${PACKAGER_DIR}/build"
git clone https://github.com/openfheorg/openfhe-development.git \
    "${PACKAGER_DIR}/build/openfhe-development"
git -C "${PACKAGER_DIR}/build/openfhe-development" checkout --detach "${OPENFHE_CORE_COMMIT}"
git -C "${PACKAGER_DIR}/build/openfhe-development" submodule update --init --recursive
[[ $(git -C "${PACKAGER_DIR}/build/openfhe-development" rev-parse 'v1.5.1^{commit}') == "${OPENFHE_CORE_COMMIT}" ]]

git clone https://github.com/openfheorg/openfhe-python.git \
    "${PACKAGER_DIR}/build/openfhe-python"
git -C "${PACKAGER_DIR}/build/openfhe-python" checkout --detach "${OPENFHE_PYTHON_COMMIT}"
[[ $(git -C "${PACKAGER_DIR}/build/openfhe-python" rev-parse 'v1.5.1.0^{commit}') == "${OPENFHE_PYTHON_COMMIT}" ]]

sed -i.bak "s/^OS_NAME=.*/OS_NAME=${OS_NAME}/" "${PACKAGER_DIR}/ci-vars.sh"
sed -i.bak "s/^OS_RELEASE=.*/OS_RELEASE=${OS_RELEASE}/" "${PACKAGER_DIR}/ci-vars.sh"
sed -i.bak 's/^OPENFHE_TAG=.*/OPENFHE_TAG=v1.5.1/' "${PACKAGER_DIR}/ci-vars.sh"
sed -i.bak 's/^OPENFHE_PYTHON_TAG=.*/OPENFHE_PYTHON_TAG=v1.5.1.0/' "${PACKAGER_DIR}/ci-vars.sh"
sed -i.bak "s/^PARALELLISM=.*/PARALELLISM=${OPENFHE_BUILD_JOBS:-4}/" "${PACKAGER_DIR}/ci-vars.sh"
rm -f "${PACKAGER_DIR}/ci-vars.sh.bak"

(
    cd "${PACKAGER_DIR}"
    export PATH="${BUILD_ROOT}/python-bin:${PATH}"
    # shellcheck disable=SC1091
    . ./scripts/get-env.sh
    ./scripts/build-binaries.sh
    ./scripts/compose-openfhe-python-wheel.sh
)

[[ $(git -C "${PACKAGER_DIR}/build/openfhe-development" rev-parse HEAD) == "${OPENFHE_CORE_COMMIT}" ]]
[[ $(git -C "${PACKAGER_DIR}/build/openfhe-python" rev-parse HEAD) == "${OPENFHE_PYTHON_COMMIT}" ]]

BUILD_PYTHON="${PACKAGER_DIR}/env_for_openfhe_wheel/bin/python"
UNTAGGED_WHEEL=$(find "${PACKAGER_DIR}/build/dist" -name 'openfhe-*-py3-none-any.whl' -print -quit)
if [[ -z ${UNTAGGED_WHEEL} ]]; then
    echo "OpenFHE packager did not produce a wheel" >&2
    exit 1
fi

${BUILD_PYTHON} -m wheel tags --remove \
    --python-tag cp313 \
    --abi-tag cp313 \
    --platform-tag "${PLATFORM_TAG}" \
    "${UNTAGGED_WHEEL}"

TAGGED_WHEEL=$(find "${PACKAGER_DIR}/build/dist" -name "openfhe-*-cp313-cp313-${PLATFORM_TAG}.whl" -print -quit)
REPACK_DIR="${BUILD_ROOT}/repack"
mkdir -p "${REPACK_DIR}/unpack" "${REPACK_DIR}/dist"
${BUILD_PYTHON} -m wheel unpack --dest "${REPACK_DIR}/unpack" "${TAGGED_WHEEL}"
WHEEL_METADATA=$(find "${REPACK_DIR}/unpack" -path '*/openfhe-*.dist-info/WHEEL' -print -quit)
sed -i.bak 's/^Root-Is-Purelib: true$/Root-Is-Purelib: false/' "${WHEEL_METADATA}"
rm -f "${WHEEL_METADATA}.bak"
UNPACKED_ROOT=$(find "${REPACK_DIR}/unpack" -mindepth 1 -maxdepth 1 -type d -print -quit)
${BUILD_PYTHON} -m wheel pack --dest-dir "${REPACK_DIR}/dist" "${UNPACKED_ROOT}"

FINAL_WHEEL=$(find "${REPACK_DIR}/dist" -name '*.whl' -print -quit)
install -m 0644 "${FINAL_WHEEL}" "${OUTPUT_DIR}/"
sha256sum "${OUTPUT_DIR}/$(basename "${FINAL_WHEEL}")" 2>/dev/null || shasum -a 256 "${OUTPUT_DIR}/$(basename "${FINAL_WHEEL}")"
