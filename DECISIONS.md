# Architecture Decisions

## ADR-001: Native SwiftUI

**Decision:** Build the iPhone prototype natively with SwiftUI.

**Why:** The product depends on iOS location APIs, offline state, haptics, accessibility, and eventually StoreKit/App Clips. Native SwiftUI keeps the prototype small and makes those platform features straightforward.

## ADR-002: iOS 17 minimum

**Decision:** Support iOS 17 and later for the prototype.

**Why:** This provides modern SwiftUI APIs while retaining a broad enough device window for field testing. Revisit before public launch using actual audience/device data.

## ADR-003: XcodeGen source of truth

**Decision:** Commit `project.yml`, not generated `.xcodeproj` state.

**Why:** Project configuration stays readable, reviewable, and reproducible. A one-command bootstrap generates the local Xcode project.

## ADR-004: Offline-first, no required backend

**Decision:** The prototype must launch and function without a server.

**Why:** The first validation is the in-park hunt loop. Accounts, remote sync, ads, and community features would add complexity before they provide validated value.

## ADR-005: Feature-first folder layout

**Decision:** Organize application screens/flows under `Features/`, shared capabilities under `Core/`, and composition under `App/`.

**Why:** It supports incremental numbered efforts without prematurely creating a large framework hierarchy.
