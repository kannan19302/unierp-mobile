# unierp-mobile

**Layer L5 — Client** of the [UniERP](../unierp-platform) platform.
Depends on: the SDK (Dart).

## What this is

The Flutter application.

## The invariant this repository owns

Different language, different toolchain, different release cadence — app-store review does not fit a platform train.

## The rule that applies everywhere

A repository may depend only on published artifacts of a **strictly lower
layer** — never sideways within a layer, never upward. A cycle is not
discouraged; it is unrepresentable, because the lower layer's package cannot
name the higher one.

See the [platform overview](../unierp-platform/README.md) for the full map, and
[`PLATFORM_ARCHITECTURE.md`](../ERPSys/docs/PLATFORM_ARCHITECTURE.md) § 4.2 for
the reasoning.

## Licence

AGPL-3.0.
