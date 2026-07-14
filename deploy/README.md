# Product deployment

FHE-Privacy owns the user-facing installation and lifecycle while deploying components as separate
processes and security principals.

For local installations, the installer will install a prebuilt, checksum-pinned OpenShell host
package and start the OpenShell Gateway as a separate service. For Kubernetes, the FHE-Privacy
umbrella chart will pin the OpenShell OCI chart and images while deploying separate FHE-Privacy
workloads, service accounts, and network policies.

No deployment may place the Secure Gateway and OpenShell Gateway in the same process or grant them
the same filesystem, key, Vault, or reveal credentials.
