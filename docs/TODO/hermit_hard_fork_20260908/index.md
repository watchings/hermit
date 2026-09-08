---
title: Hermit hard fork and embedded Hermes runtime
status: in-progress
---

# Hermit hard fork and embedded Hermes runtime

## Scope

This is a hard fork. The application and package identity will become Hermit without
compatibility aliases for the former project identity.

Hermes Agent, Hermes WebUI, and the Hermes Android client are upstream projects with
different runtime boundaries. Hermit must package the Hermes Python agent and its
runtime into the APK; a remote WebUI is not an acceptable implementation.

## Work units

1. Inventory and pin the upstream Hermes sources, Python runtime, native wheels,
   transitive licenses, and supported Android ABIs.
2. Add an APK asset/native-runtime assembly step that produces a self-contained
   Python environment during the Android build.
3. Add a process supervisor and local IPC boundary for starting, stopping, logging,
   and health-checking Hermes Agent inside the application sandbox.
4. Persist the Hermes model/provider selection in the existing settings system and
   expose it through the settings UI.
5. Adapt the Hermes WebUI protocol to an in-process local UI boundary without
   requiring a remote server.
6. Rename the hard-fork application/package identity and update CI artifact names.
7. Publish a third-party notices inventory and verify LGPL/MIT obligations.

## Constraints

- Do not preserve the former application/package identity.
- Do not implement a remote-only Hermes WebUI integration.
- Do not silently substitute the existing native agent for Hermes Agent.
- Do not ship unpinned or unlicensed Python dependencies.
