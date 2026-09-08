# Delivery checklist

## Scope gate

- [ ] Hard-fork package and application identity is Hermit
- [ ] No compatibility alias for the former project identity remains
- [ ] No remote-only Hermes WebUI dependency remains
- [ ] Supported Android ABIs are explicitly documented

## Bundle gate

- [ ] Hermes sources and runtime inputs are pinned
- [ ] Checksums and the runtime manifest are committed
- [ ] Bundle assembly is reproducible and offline during Gradle packaging
- [ ] APK contains only the declared runtime contents

## Lifecycle gate

- [ ] Local IPC schema is versioned
- [ ] Start, stop, cancellation, health, timeout, and crash states are observable
- [ ] Service shutdown closes the child process and IPC channel
- [ ] Logs redact secrets and have bounded retention

## Settings and UI gate

- [ ] Provider/model selection persists across restart
- [ ] Invalid configuration has an actionable UI error
- [ ] Streaming, cancellation, and agent failures render locally
- [ ] Credentials use secure storage and never enter logs or exports

## License and CI gate

- [ ] Direct and transitive notices inventory is present
- [ ] LGPL/MIT obligations and source references are verified
- [ ] CI checks lockfile drift, checksums, ABI, notices, and identity
- [ ] Release artifacts include manifest, notices, and reproducibility hashes

## Evidence and handoff

Record links to the bundle manifest, CI run, APK checksum, notices archive, and
review decisions here before marking the folder complete.

- Bundle manifest:
- CI run:
- APK checksum:
- Notices archive:
- Review decision:

When every gate is checked and the evidence links are populated, append `[DONE]`
to the completed stage documents and move this TODO folder to the legacy TODO
location in a separate documentation change.
