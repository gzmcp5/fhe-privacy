# Product deployment

FHE-Privacy owns the user-facing installation and lifecycle while deploying components as separate
processes and security principals.

For local installations, the installer will install a prebuilt, checksum-pinned OpenShell host
package and start the OpenShell Gateway as a separate service. For Kubernetes, the FHE-Privacy
umbrella chart will pin the OpenShell OCI chart and images while deploying separate FHE-Privacy
workloads, service accounts, and network policies.

No deployment may place the Secure Gateway and OpenShell Gateway in the same process or grant them
the same filesystem, key, Vault, or reveal credentials.

Developer runtime inputs are reproducible from `versions.lock`. Use
`tools/openshell/install.sh` for the pinned platform binary and `tools/openfhe/build-wheel.sh` for the
platform-native OpenFHE wheel; see the README beside each script for validation requirements.
