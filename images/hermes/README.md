# Hermes sandbox image

This directory will build the OCI workload image that OpenShell runs as the sealed sandbox. It may
contain Hermes, the stateless FHE-Privacy MCP Bridge, and their runtime dependencies.

It must not contain the Secure Gateway, Privacy Core, Vault, secret shares, reveal implementation,
host-only credentials, or plaintext fixtures. Release manifests must pin the final image by digest.
