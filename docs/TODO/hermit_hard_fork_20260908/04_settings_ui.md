# Settings and UI

## Existing state

The existing settings system does not persist the Hermes provider/model contract,
and the Hermes WebUI cannot be used as a remote-only page. There is no defined
mapping between settings, the local IPC request, and the displayed conversation
state.

## Intended state

The settings screen exposes the supported Hermes providers and models from a
versioned capability list. Selection is validated, persisted through the
existing settings system, and supplied to the local agent on the next start.
The UI consumes the local IPC event stream rather than loading a remote URL.

Credentials are referenced through the platform secure storage mechanism. They
are never rendered as setting values, serialized into logs, or sent through a
general-purpose navigation argument.

## Implementation steps

1. Define the provider/model data model and its stable persisted keys.
2. Add validation for unsupported or incomplete selections before saving.
3. Add the settings controls, descriptions, and failure states.
4. Load the persisted selection before starting the agent and show the active
   selection in the conversation surface.
5. Map IPC streaming events, cancellation, and errors to local UI state.
6. Replace remote WebUI navigation with the in-process local UI boundary.
7. Document which settings changes require an agent restart.

## Acceptance criteria

- A provider/model choice survives an app restart.
- Invalid selections cannot start the agent and show an actionable error.
- The UI shows agent health, streaming output, cancellation, and failures.
- No feature depends on a remote Hermes WebUI URL.
- Secrets are absent from persisted settings exports and application logs.

## Handoff

- [ ] Persisted keys and capability list documented
- [ ] Local UI state mapping reviewed
- [ ] Restart and invalid-setting evidence attached to the delivery checklist
