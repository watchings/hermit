# Licenses and CI

## Existing state

The fork does not yet publish a complete inventory for the embedded Python,
native, rootfs, Hermes, and WebUI components. CI artifact names and release
checks still reflect the former application identity.

## Intended state

CI builds the hard fork from locked inputs, verifies the bundle, generates an
inspectable third-party notices inventory, and publishes artifacts under the
Hermit identity. The inventory includes direct and transitive dependencies,
license text, source references, and the exact version or revision shipped.

## Implementation steps

1. Generate the dependency inventory from the bundle manifest and lockfiles.
2. Store complete LGPL, MIT, and other required notices with the release
   inputs; preserve source-offer information where required.
3. Add CI checks for lockfile drift, checksum mismatch, missing notices, ABI
   mismatch, and accidental former-identity artifact names.
4. Separate network acquisition from the offline bundle and APK jobs.
5. Publish the APK, bundle manifest, notices archive, and reproducibility hashes.
6. Update package identity, task names, artifact names, and release metadata.

## Acceptance criteria

- CI fails when a shipped component has no version, checksum, source reference,
  or license record.
- The release artifact contains an inspectable third-party notices inventory.
- LGPL obligations and corresponding source availability are verified.
- Offline packaging succeeds using only CI-cached, locked inputs.
- No release artifact or package metadata uses the former application identity.

## Handoff

- [ ] Notices inventory generated and reviewed
- [ ] CI jobs and artifact names updated
- [ ] License and reproducibility evidence attached to the delivery checklist
