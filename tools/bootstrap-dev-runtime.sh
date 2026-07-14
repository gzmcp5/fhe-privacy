#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON=${PYTHON:-python3.13}
WHEEL_DIR="${ROOT_DIR}/vendor/wheels"
TEST_ENV="${ROOT_DIR}/build/openfhe-wheel-test"

cd "${ROOT_DIR}"

if ! command -v "${PYTHON}" >/dev/null 2>&1; then
    echo "Development bootstrap requires Python 3.13; '${PYTHON}' was not found" >&2
    exit 1
fi
PYTHON=$("${PYTHON}" -c 'import os, sys; print(os.path.realpath(sys.executable))')

echo "Preparing the checksum-pinned OpenShell runtime"
./tools/openshell/install.sh --allow-unvalidated

case "${FHE_PRIVACY_RUNTIME_TARGET:-}:$(uname -s):$(uname -m)" in
    windows_wsl2_amd64:Linux:x86_64) WHEEL_TARGET=windows_wsl2_amd64 ;;
    :Linux:x86_64) WHEEL_TARGET=linux_amd64 ;;
    :Darwin:arm64) WHEEL_TARGET=macos_arm64 ;;
    *)
        echo "Unsupported OpenFHE development target: $(uname -s) $(uname -m)" >&2
        exit 1
        ;;
esac

EXPECTED_WHEEL=$(
    "${PYTHON}" - "${ROOT_DIR}/versions.lock" "${WHEEL_TARGET}" <<'PY'
import pathlib
import sys
import tomllib

lock = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
print(lock["openfhe"]["local"][sys.argv[2]]["wheel"])
PY
)

if [[ ${WHEEL_TARGET} == windows_wsl2_amd64 ]]; then
    if ! grep -qi 'microsoft-standard-WSL2' /proc/sys/kernel/osrelease; then
        echo "Windows runtime bootstrap must run inside WSL 2" >&2
        exit 1
    fi
    DISTRO_RELEASE=$(
        "${PYTHON}" - "${ROOT_DIR}/versions.lock" <<'PY'
import pathlib
import tomllib

lock = tomllib.loads(pathlib.Path(__import__("sys").argv[1]).read_text())
print(lock["openfhe"]["local"]["windows_wsl2_amd64"]["distro_release"])
PY
    )
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ ${VERSION_ID} != "${DISTRO_RELEASE}" ]]; then
        echo "The locked Windows runtime requires Ubuntu ${DISTRO_RELEASE} under WSL 2, found ${VERSION_ID}" >&2
        exit 1
    fi
fi

if [[ ! -f ${WHEEL_DIR}/${EXPECTED_WHEEL} ]]; then
    echo "Building the pinned OpenFHE wheel for ${WHEEL_TARGET}"
    PYTHON="${PYTHON}" ./tools/openfhe/build-wheel.sh
fi

WHEEL_PATH="${WHEEL_DIR}/${EXPECTED_WHEEL}"
if [[ ! -f ${WHEEL_PATH} ]]; then
    echo "OpenFHE build did not produce the locked wheel ${EXPECTED_WHEEL}" >&2
    exit 1
fi

rm -rf "${TEST_ENV}"
"${PYTHON}" -m venv "${TEST_ENV}"
"${TEST_ENV}/bin/pip" install "${WHEEL_PATH}"
"${TEST_ENV}/bin/python" tools/openfhe/smoke.py

if command -v sha256sum >/dev/null 2>&1; then
    WHEEL_SHA256=$(sha256sum "${WHEEL_PATH}" | awk '{print $1}')
else
    WHEEL_SHA256=$(shasum -a 256 "${WHEEL_PATH}" | awk '{print $1}')
fi

EXPECTED_SHA256=$(
    "${PYTHON}" - "${ROOT_DIR}/versions.lock" "${WHEEL_TARGET}" <<'PY'
import pathlib
import sys
import tomllib

lock = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
print(lock["openfhe"]["local"][sys.argv[2]]["sha256"])
PY
)

if [[ ${EXPECTED_SHA256} != "UNVALIDATED" && ${WHEEL_SHA256} != "${EXPECTED_SHA256}" ]]; then
    echo "OpenFHE wheel checksum mismatch: expected ${EXPECTED_SHA256}, got ${WHEEL_SHA256}" >&2
    exit 1
fi

echo "OpenFHE wheel: ${WHEEL_PATH}"
echo "OpenFHE SHA-256: ${WHEEL_SHA256}"
if [[ ${EXPECTED_SHA256} == "UNVALIDATED" ]]; then
    echo "${WHEEL_TARGET} remains UNVALIDATED; record this checksum only after the required platform tests pass"
fi
echo "Development runtime bootstrap completed"
