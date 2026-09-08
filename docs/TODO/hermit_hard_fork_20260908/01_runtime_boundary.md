# Runtime boundary

## Existing state

The Android application currently relies on native Android, Kotlin, JavaScript,
and an existing terminal/user-space integration. It has no embedded CPython
distribution or APK build step for Python wheels.

## Intended state

The APK build must receive a reproducible Hermes bundle containing:

- a pinned CPython runtime suitable for the supported Android ABI
- an Ubuntu AArch64 PRoot userspace containing the Python interpreter
- Hermes Agent source and its locked Python dependency graph
- required pure-Python packages and ABI-matched native extensions
- Hermes WebUI source/assets needed by the local UI boundary
- license and source notices for every bundled component

The runtime must execute inside the application sandbox, expose a narrow local
IPC protocol to Kotlin, and be supervised by an Android service so that process
crashes, cancellation, and app restarts are observable.

## Acceptance criteria

- A clean CI checkout can assemble the bundle without network access during the
  Gradle task itself.
- The runtime manifest identifies one exact AArch64 rootfs and its SHA-256
  before it is copied into an APK.
- First application initialization starts the bundled agent locally.
- The settings screen can select and persist the Hermes model/provider.
- No feature depends on a remote Hermes WebUI URL.
- The release artifact contains an inspectable third-party notices inventory.
