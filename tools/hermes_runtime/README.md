# Hermit Hermes PRoot runtime

Hermes Agent runs inside an AArch64 Linux userspace rather than directly in the
Android VM. The supported runtime is an Ubuntu AArch64 rootfs launched through
the PRoot binary already provided by the terminal environment.

## Bundle layout

The release bundle is installed under the application files directory:

```text
usr/
  bin/proot
  var/lib/proot-distro/installed-rootfs/ubuntu/
hermes/
  agent/
  requirements-aarch64.lock
  LICENSES.txt
```

`app/src/main/assets/hermes/runtime.json` pins the runtime contract. The
manifest contains a SHA-256 for every cache artifact. The offline preparation
script refuses missing, malformed, repeated, or placeholder hashes and verifies
each provisioned file or directory before copying it into the APK assets.

The rootfs must contain Python 3, certificates, `/bin/sh`, and the shared
libraries required by the locked Hermes dependencies. Python wheels with native
code must be built for AArch64 inside this userspace and listed in
`requirements-aarch64.lock`; host Linux or manylinux wheels are not valid
inputs.

## Build policy

Runtime archives are provisioned outside this repository and restored in CI
from the hash-keyed dependency cache. `prepare_runtime.sh` consumes that
directory and does not download a rootfs, PRoot, or Python package while
assembling the APK. This checkout intentionally does not contain the runtime
binaries; a cache must be provisioned before the workflow can package them.

The provisioned cache is published as `hermes-runtime-aarch64.tar.gz` under the
immutable `hermes-runtime-v1` GitHub release, together with its `.sha256`
checksum, manifest, lockfile, and notices. Android CI downloads that release
asset and verifies it before copying files into APK assets. The
`Hermes Runtime Release` workflow is the supported manual update path. It
builds the pinned `python:3.12-bookworm` image for `linux/arm64` with QEMU,
installs Hermes Agent and Hermes WebUI at the requested commit SHAs, exports
the container filesystem, and uploads the resulting tarball and checksum.

The bundle must include the licenses and source references for Ubuntu, PRoot,
CPython, Hermes Agent, Hermes WebUI assets, and every Python dependency. MIT
notices do not replace the LGPL-3 corresponding-source obligations of Hermit.
