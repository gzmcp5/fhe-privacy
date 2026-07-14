#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
LOCK_FILE="${ROOT_DIR}/versions.lock"
ARTIFACT_ROOT=${OPENSHELL_ARTIFACT_ROOT:-"${ROOT_DIR}/artifacts"}
PYTHON=${PYTHON:-python3}
ALLOW_UNVALIDATED=false

if [[ ${1:-} == "--allow-unvalidated" ]]; then
    ALLOW_UNVALIDATED=true
    shift
fi
if [[ $# -ne 0 ]]; then
    echo "usage: $0 [--allow-unvalidated]" >&2
    exit 2
fi

case "${FHE_PRIVACY_RUNTIME_TARGET:-}:$(uname -s):$(uname -m)" in
    windows_wsl2_amd64:Linux:x86_64) TARGET=windows_wsl2_amd64 ;;
    :Linux:x86_64) TARGET=linux_amd64 ;;
    :Linux:aarch64 | :Linux:arm64) TARGET=linux_arm64 ;;
    :Darwin:arm64) TARGET=macos_arm64 ;;
    *)
        echo "Unsupported OpenShell target: ${FHE_PRIVACY_RUNTIME_TARGET:-native} $(uname -s) $(uname -m)" >&2
        exit 1
        ;;
esac

if [[ ${TARGET} == windows_wsl2_amd64 ]] && ! grep -qi 'microsoft-standard-WSL2' /proc/sys/kernel/osrelease; then
    echo "windows_wsl2_amd64 must run inside WSL 2" >&2
    exit 1
fi

METADATA=$(
    "${PYTHON}" - "${LOCK_FILE}" "${TARGET}" <<'PY'
import pathlib
import sys
import tomllib

lock = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
openshell = lock["openshell"]
target = openshell["local"][sys.argv[2]]
values = (
    openshell["version"],
    openshell["download_base_url"],
    target["asset"],
    target["sha256"],
    target["compatibility"],
)
if any(any(character.isspace() for character in value) for value in values):
    raise SystemExit("OpenShell lock metadata must not contain whitespace")
print(" ".join(values))
PY
)
read -r VERSION DOWNLOAD_BASE_URL ASSET EXPECTED_SHA256 COMPATIBILITY <<EOF
${METADATA}
EOF

if [[ ${COMPATIBILITY} != "validated" && ${ALLOW_UNVALIDATED} != true ]]; then
    echo "OpenShell ${TARGET} is ${COMPATIBILITY}; rerun with --allow-unvalidated only for platform verification" >&2
    exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT
ARCHIVE="${TEMP_DIR}/${ASSET}"
URL="${DOWNLOAD_BASE_URL}/${ASSET}"

echo "Downloading ${URL}"
curl --fail --location --silent --show-error "${URL}" --output "${ARCHIVE}"

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_SHA256=$(sha256sum "${ARCHIVE}" | awk '{print $1}')
else
    ACTUAL_SHA256=$(shasum -a 256 "${ARCHIVE}" | awk '{print $1}')
fi
if [[ ${ACTUAL_SHA256} != "${EXPECTED_SHA256}" ]]; then
    echo "OpenShell checksum mismatch: expected ${EXPECTED_SHA256}, got ${ACTUAL_SHA256}" >&2
    exit 1
fi

EXTRACT_DIR="${TEMP_DIR}/extract"
mkdir -p "${EXTRACT_DIR}"
tar -xzf "${ARCHIVE}" -C "${EXTRACT_DIR}"
if [[ ! -f ${EXTRACT_DIR}/openshell ]]; then
    echo "OpenShell archive does not contain the expected openshell binary" >&2
    exit 1
fi
chmod 0755 "${EXTRACT_DIR}/openshell"

REPORTED_VERSION=$("${EXTRACT_DIR}/openshell" --version)
if [[ ${REPORTED_VERSION} != "openshell ${VERSION}" ]]; then
    echo "OpenShell version mismatch: expected 'openshell ${VERSION}', got '${REPORTED_VERSION}'" >&2
    exit 1
fi

INSTALL_DIR="${ARTIFACT_ROOT}/openshell/${VERSION}/bin"
mkdir -p "${INSTALL_DIR}" "${ARTIFACT_ROOT}/bin"
install -m 0755 "${EXTRACT_DIR}/openshell" "${INSTALL_DIR}/openshell"
ln -sfn "../openshell/${VERSION}/bin/openshell" "${ARTIFACT_ROOT}/bin/openshell"

echo "Installed ${REPORTED_VERSION} for ${TARGET} at ${INSTALL_DIR}/openshell"
