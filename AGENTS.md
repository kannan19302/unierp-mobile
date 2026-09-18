<!-- UniERP-Agent-Protocol: 1.1.0 -->
# UniERP Repository Agent Entrypoint: Mobile Client (`mobile`)

This repository is one delivery unit in the UniERP polyrepo. Before analysis, planning, review, or mutation, every
AI agent from every provider MUST read and follow:

1. the workspace entrypoint at [`../AGENTS.md`](../AGENTS.md);
2. the canonical standard at
   [`../platform/docs/standards/AI_AGENT_DEVELOPMENT_PROTOCOL.md`](../platform/docs/standards/AI_AGENT_DEVELOPMENT_PROTOCOL.md);
3. the owning platform documents selected through
   [`../platform/docs/PLATFORM_CATALOG.md`](../platform/docs/PLATFORM_CATALOG.md).

If the workspace entrypoint or canonical standard is unavailable, the protocol bundle is incomplete. The agent
MUST stop before mutation and report the missing dependency. This bootstrap adds no weaker or conflicting rules.
Repository-specific additions may be appended below only when they narrow implementation behavior without
redefining platform ownership, security, contracts, or cross-platform standards.

---

## 1. Repository Identity & Mission

- **Repository**: `mobile`
- **Platform Owner**: `PLT-MOB` (Mobile Platform Operations)
- **Architectural Layer**: **Layer 5 (Multi-Platform Client)**
- **Runtime Port**: `4006` (Flutter Web preview)
- **Mission**: Native Flutter multi-platform client application for iOS, Android, and Web — providing field operations, warehouse barcode scanning, mobile approvals, and offline-first data synchronization.

---

## 2. Zero-Trust Security & Mobile Invariants

1. **Secure Storage**:
   - Authentication tokens, cryptographic keys, and offline encrypted caches must use platform-native secure storage (`flutter_secure_storage` via Keychain/Keystore).
   - Zero credentials stored in cleartext SharedPreferences or files.
2. **Offline Data Synchronization**:
   - Local sqlite database with row-level encryption.
   - Idempotent event synchronization queues via client outbox.
3. **Strict Tenancy**:
   - All mobile API requests attach verified JWT bearer tokens with active tenant ID.

---

## 3. Industrial Software Engineering Standards

1. **Zero Analyzer Warnings**:
   - `flutter analyze` must pass with exactly 0 errors and 0 warnings.
2. **Strata Mobile Design Language**:
   - Mobile adaptations of Strata DL 2.0 design tokens.
   - Responsive touch targets ($\ge 44 \times 44$ dp).
   - Dynamic dark/light theme switching.

---

## 4. Verification Gates & Mandatory Toolchain

Before declaring any cycle `DONE`, run and verify:

```powershell
flutter analyze             # Static analysis check (0 warnings required)
flutter test                # Flutter widget and unit test suite
```
