# Hermit Hermes PRoot runtime

Hermes Agent runs inside an AArch64 Linux userspace rather than directly in the
Android VM. The supported runtime is an Ubuntu AArch64 rootfs launched through
the PRoot binary already provided by the terminal environment.

## Bundle layout

The Docker-provisioned assets use this layout:

```text
usr/
  bin/proot
  var/lib/proot-distro/installed-rootfs/ubuntu/
hermes/
  webui/
  requirements-aarch64.lock
  LICENSES.txt
```

`app/src/main/assets/hermes/runtime.json` records the image references used for
the build. The Docker preparation script copies only the pulled AArch64
container filesystem into APK assets.

The rootfs must contain Python 3, certificates, `/bin/sh`, and the shared
libraries required by the locked Hermes dependencies. Python wheels with native
code must be built for AArch64 inside this userspace and listed in
`requirements-aarch64.lock`; host Linux or manylinux wheels are not valid
inputs.

## Build policy

The runtime is provisioned directly by Android CI. No runtime archive is
created, checked into the repository, or uploaded to a release.

Android CI pulls the AArch64 `python:3.12-bookworm` image and
`ghcr.io/nesquena/hermes-webui:latest` directly. It installs PRoot into the
WebUI container, exports that container filesystem directly into APK assets,
and records the image references in `hermes/runtime.json`; no runtime archive
or runtime release is created.

The bundle must include the licenses and source references for Ubuntu, PRoot,
CPython, Hermes Agent, Hermes WebUI assets, and every Python dependency. MIT
notices do not replace the LGPL-3 corresponding-source obligations of Hermit.
