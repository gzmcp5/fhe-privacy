# OpenShell adapter

This directory owns the FHE-Privacy-to-OpenShell integration. The adapter will call the OpenShell
control-plane API; production code must not parse interactive CLI output or embed the OpenShell
Gateway in the Secure Gateway process.

The adapter contract must cover:

- creation of a sealed, managed-only Hermes sandbox;
- verification of sandbox identity, policy revision, and short session lease;
- denial of connect/SSH, exec, sync, forwarding, and service exposure;
- delivery of masked envelopes without a raw-input fallback;
- session teardown and capability revocation; and
- explicit compatibility checks against `versions.lock`.

OpenShell credentials must grant only the control-plane operations required by this adapter. They
must not grant access to the Privacy Core host-only interface, Vault, key shares, or reveal plane.
