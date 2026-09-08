# Hermit Hermes runtime setup

Hermes runs inside an AArch64 Linux userspace rather than directly in the
Android VM. The runtime is not part of the APK. During first setup,
`app/src/main/assets/hermes/download_runtime.sh` downloads the
`ghcr.io/nesquena/hermes-webui:latest` arm64 image and Alpine's static PRoot
binary into the app-private runtime directory.

The setup script prints each image layer and uses curl's progress bar for both
the image blobs and PRoot download, so its stdout/stderr can be attached to the
in-app terminal.

## Runtime layout

The installed runtime uses this layout:

```text
usr/
  bin/proot
  var/lib/proot-distro/installed-rootfs/ubuntu/
hermes/
  image
  image-digest
```

The script writes the selected image digest to `hermes/image-digest` and writes
the image reference to `hermes/image`. The runtime directory is only populated
after all layers have been downloaded and extracted.

The rootfs must contain Python 3, certificates, `/bin/sh`, and the shared
libraries required by the locked Hermes dependencies. Python wheels with native
code must be built for AArch64 inside this userspace and listed in
`requirements-aarch64.lock`; host Linux or manylinux wheels are not valid
inputs.

## Build policy

Android CI does not pull or package the runtime. No runtime archive, container
filesystem, or runtime release is created by the APK build.

The source repository must retain the licenses and source references for Ubuntu,
PRoot, CPython, Hermes Agent, Hermes WebUI assets, and every Python dependency.
MIT notices do not replace the LGPL-3 corresponding-source obligations of
Hermit.
