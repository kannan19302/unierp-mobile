    <!-- UniERP-Agent-Protocol: 1.1.0 -->
    # mobile agent rules

    This is the only repository agent instruction file. Read [the workspace entrypoint](../AGENTS.md),
    the [canonical protocol](../platform/docs/standards/AI_AGENT_DEVELOPMENT_PROTOCOL.md),
    the enterprise brain, applicable accepted ADRs and the owning platform requirements before
    material work. Follow authority precedence; this file narrows implementation behavior only.
    If a required authority is missing, stop before mutation.

    **Layer:** L5. **Accountable platform:** PLT-MOB. **Scope:** Mobile client of published services.
    Resolve actual dependencies, packages and scripts from current manifests and the platform catalog.
    Preserve unrelated changes. Define numbered acceptance criteria and a knowledge delta before editing.
    For coordinated changes, publish the change contract, validate upstream first, and hand off
    to downstream consumers with exact evidence.

    ## Repository rules

    - Use published contracts and native secure storage. Never keep credentials or sensitive offline data in cleartext.
- Verify tenant context on every server request; offline queues must be idempotent, encrypted where applicable and conflict-aware.
- Consume approved design tokens and prove touch, keyboard/assistive-technology, offline and recovery behavior for supported journeys.

    ## Verification

    Run applicable commands from this repository, plus risk-specific contract, security, data,
    accessibility, integration, migration or release gates required by the canonical protocol:
    flutter analyze; flutter test; focused integration tests for changed journeys

    A command's presence here is not proof that it ran. Report exact results, failures and NOT RUN
    reasons; review the diff; then follow the canonical status and source-control procedure.
