---
title: Hermit hard fork and embedded Hermes runtime
status: in-progress
fork_repository: pending
---

# Hermit hard fork and embedded Hermes runtime

## Scope

This is a hard fork. The application and package identity will become Hermit without
compatibility aliases for the former project identity.

Hermes Agent, Hermes WebUI, and the Hermes Android client are upstream projects with
different runtime boundaries. Hermit must package the Hermes Python agent and its
runtime into the APK; a remote WebUI is not an acceptable implementation.

## Work units

1. [Bundle pipeline](02_bundle_pipeline.md): inventory and pin the upstream Hermes
   sources, Python runtime, native wheels, transitive licenses, and supported
   Android ABIs.
2. [Lifecycle and IPC](03_lifecycle_ipc.md): add a process supervisor and local
   IPC boundary for starting, stopping, logging, and health-checking Hermes Agent.
3. [Settings and UI](04_settings_ui.md): persist the Hermes model/provider
   selection and adapt the WebUI protocol to an in-process local UI boundary.
4. [Licenses and CI](05_licenses_ci.md): publish third-party notices, verify
   LGPL/MIT obligations, and rename CI artifacts for the hard fork.
5. [Delivery checklist](06_delivery_checklist.md): record release gates, evidence,
   and the hand-off conditions for each work unit.

## Constraints

- Do not preserve the former application/package identity.
- Do not implement a remote-only Hermes WebUI integration.
- Do not silently substitute the existing native agent for Hermes Agent.
- Do not ship unpinned or unlicensed Python dependencies.
