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
`rootfsSha256` value must be replaced by the hash of the exact rootfs archive
before publishing an APK. Gradle and release automation must verify this hash
before copying the bundle into the APK.

The rootfs must contain Python 3, certificates, `/bin/sh`, and the shared
libraries required by the locked Hermes dependencies. Python wheels with native
code must be built for AArch64 inside this userspace and listed in
`requirements-aarch64.lock`; host Linux or manylinux wheels are not valid
inputs.

## Build policy

Runtime archives are prepared in CI and checked into the dependency cache with
their SHA-256 manifest. The Gradle task consumes that prepared directory and
does not download a rootfs or Python package while assembling the APK.

The bundle must include the licenses and source references for Ubuntu, PRoot,
CPython, Hermes Agent, Hermes WebUI assets, and every Python dependency. MIT
notices do not replace the LGPL-3 corresponding-source obligations of Hermit.
