# Lifecycle and local IPC

## Existing state

The application has no Hermes-specific supervisor or local protocol for
communicating with an embedded Python process. Startup, cancellation, crash
reporting, and app-restart behavior are therefore undefined.

## Intended state

An Android service owns one Hermes Agent process inside the application sandbox.
Kotlin communicates with it through a narrow, versioned local IPC channel. The
agent never requires a listening socket exposed outside the app.

The protocol must provide:

- `start` with the selected provider/model and required credentials reference
- `stop` with cancellation semantics
- request/response messages with correlation IDs
- streaming assistant events and structured error events
- `health` with protocol and agent versions
- process exit, startup timeout, and protocol violation events

## Implementation steps

1. Define the message schema, protocol version, size limits, and error codes.
2. Start the service only after bundle verification and settings initialization.
3. Pass configuration through a private channel; do not put secrets in intents,
   logs, or persisted JSON.
4. Tie the child process lifetime to the service and close IPC on service stop.
5. Surface startup, cancellation, crash, and health state to the UI.
6. Make app restart reconstruct state from persisted settings and a fresh health
   handshake.
7. Add structured logs with redaction and bounded retention.

## Acceptance criteria

- First initialization starts exactly one local agent process.
- Stop and cancellation terminate the active request and child process cleanly.
- A crash or startup timeout becomes an observable error without hanging the UI.
- Health responses include the protocol version and agent version.
- No remote Hermes WebUI URL or externally reachable agent port is required.

## Handoff

- [ ] IPC schema and lifecycle state machine reviewed
- [ ] Supervisor ownership and shutdown behavior documented
- [ ] Crash, timeout, and restart evidence attached to the delivery checklist
