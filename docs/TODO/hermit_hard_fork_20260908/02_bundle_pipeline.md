# Bundle pipeline

## Existing state

The Android build has no reproducible step that assembles CPython, an Ubuntu
AArch64 PRoot userspace, Hermes Agent, and its locked Python dependencies into
an APK-consumable directory. Dependency downloads are not currently separated
from the Gradle build, and there is no manifest that records the exact runtime
inputs.

## Intended state

Produce one deterministic Hermes bundle before the Android packaging task. The
bundle is an immutable build input, not a runtime download.

- Pin the Hermes Agent and WebUI source revisions.
- Pin the CPython distribution, Ubuntu AArch64 rootfs, PRoot binary, and every
  Python package and native wheel.
- Record URL, version, SHA-256, license, source location, and target ABI in a
  machine-readable manifest.
- Assemble the runtime in a staging directory, then copy only the declared
  contents into APK assets or native libraries.
- Keep host tools and build caches outside the shipped runtime.

## Implementation steps

1. Define the supported Android ABI set and reject inputs for other ABIs.
2. Add a lockfile or manifest for source archives, wheels, rootfs, and tools.
3. Add an offline-capable bundle task whose network-fetch phase runs before
   Gradle packaging.
4. Verify every archive and wheel before extraction.
5. Normalize file ownership, permissions, timestamps, and archive ordering so
   identical inputs produce identical output.
6. Emit a bundle version and SHA-256 alongside the staged bundle.
7. Make the APK packaging task depend on the verified bundle task.
8. Build the AArch64 image with Docker Buildx and QEMU from the pinned Python
   image.
9. Install Hermes Agent from `main` and Hermes WebUI from `master`, export the
   container filesystem, and record the resolved revisions in the manifest.

## Acceptance criteria

- A clean checkout with pre-fetched, locked inputs assembles without network
  access during the Gradle task.
- A changed or missing checksum fails the bundle task before APK packaging.
- The manifest identifies one exact AArch64 rootfs and its SHA-256.
- The staged bundle contains no unpinned package, host credential, or build cache.
- A second build from the same inputs has identical manifest and bundle hashes.

## Handoff

- [ ] Runtime manifest committed
- [ ] Bundle task and staging layout documented
- [ ] Offline build evidence attached to the delivery checklist
