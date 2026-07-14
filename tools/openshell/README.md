# OpenShell development runtime

FHE-Privacy pins OpenShell as an external runtime dependency. The binary is not committed to Git.
Its release, source commit, platform asset names and SHA-256 digests are recorded in
`versions.lock`. `install.sh` selects the current host entry, downloads that exact release asset,
verifies its digest and reported version, and installs it under the ignored `artifacts/` directory.

On a fresh clone, agents should normally run `./tools/bootstrap-dev-runtime.sh`. That single entry
point invokes this installer and then builds and tests the current platform's OpenFHE wheel.

Supported download targets are:

- Linux x86-64;
- Linux arm64;
- macOS 13 or later on Apple Silicon arm64.

Only Linux x86-64 is currently marked `validated`. A published upstream checksum establishes file
identity; it does not establish FHE-Privacy compatibility. For an unvalidated target, a developer
must explicitly opt in while producing the platform verification evidence:

```bash
./tools/openshell/install.sh --allow-unvalidated
artifacts/bin/openshell --version
```

The installer fails closed when the OS/CPU pair has no lock entry, the target remains unvalidated
without the explicit flag, the download digest differs, or `openshell --version` does not report the
locked release. It never resolves `latest` and does not execute an upstream install script.

Before changing a platform's `compatibility` to `validated`, run the OpenShell filesystem, network,
channel and sealed-management negative tests required by `docs/distribution-guide.md`. Record the
successful commands and environment in `progress.md`; a successful download alone is insufficient.

To test installation without modifying the repository's normal artifact directory, set an alternate
root:

```bash
OPENSHELL_ARTIFACT_ROOT=/tmp/fhe-privacy-openshell ./tools/openshell/install.sh
```

When upgrading OpenShell, review the upstream tag and commit, update all URLs/assets/digests in
`versions.lock`, and rerun every platform compatibility and release gate. Do not carry forward a
`validated` status from an older release.
