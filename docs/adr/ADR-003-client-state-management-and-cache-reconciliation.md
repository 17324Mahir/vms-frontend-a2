# Architecture Decision Record (ADR-003)
## Client State Management, Session Persistence & Cache Reconciliation

### Status
**ACCEPTED** - Implemented in Assignment 2

### Context
In Flutter Web applications, page refreshes (F5) clear the Dart in-memory VM heap, causing users to be abruptly logged out if sessions are not persisted. Furthermore, state management across fleet vehicles, drivers, documents, and maintenance logs must avoid bloated global state while ensuring immediate UI reactivity and data consistency.

### Decision
We implement a **Hybrid Reactive State & Multi-Layer Session Architecture**:

```
┌────────────────────────────────────────────────────────┐
│                   USER BROWSER / CLIENT                │
└───────────────────────────┬────────────────────────────┘
                            │ (Page Refresh / Launch)
┌───────────────────────────▼────────────────────────────┐
│                    AUTH SERVICE LAYER                  │
│                                                        │
│  1. Check in-memory `_currentSession`                  │
│  2. If null: read from `SessionStorage` (Web Storage)  │
│  3. Rehydrate session if token valid (< expires_at)    │
│  4. Centralized 401 Handler: auto sign-out & cleanup   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│              REACTIVE REPOSITORY STATE LAYER           │
│                                                        │
│ • `VehicleRepository extends ChangeNotifier`           │
│ • Local query filtering & sorting memoization          │
│ • Optimistic updates with rollback on network failure   │
│ • `ListenableBuilder` fine-grained re-renders          │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│               SEGREGATED API CLIENT CONTRACTS          │
│                                                        │
│ • `VehicleApiClient`     • `DriverApiClient`           │
│ • `DocumentApiClient`    • `MaintenanceApiClient`      │
│ • `DashboardApiClient`                                 │
└────────────────────────────────────────────────────────┘
```

#### 1. Session Storage Decision (`sessionStorage` vs `localStorage`)
- **Choice**: `window.sessionStorage` with cross-platform conditional compilation stubs.
- **Rationale**:
  - `sessionStorage` survives browser tab reloads (solving the refresh bug).
  - `sessionStorage` is automatically wiped when the browser tab closes, preventing persistent token theft on shared machines (better security posture than `localStorage`).
  - Implemented cleanly using `dart:js_interop` / `package:web/web.dart` with stub fallback for non-web environments and widget tests.

#### 2. Reactive Repository Pattern (`ChangeNotifier` & `ListenableBuilder`)
- **Choice**: Repository Pattern with Flutter foundation primitives (`ChangeNotifier`).
- **Rationale**:
  - Avoids introducing heavy third-party state libraries (Bloc, Riverpod) while providing 100% reactive state updates.
  - Testable with zero external mocking frameworks.
  - Supports dependency injection (`VehicleRepository.setInstanceForTesting(fake)`).

#### 3. Client Interface Segregation Principle (ISP)
- Rather than a giant `ApiClient`, five discrete, domain-scoped API clients manage network interaction:
  1. `VehicleApiClient`: Vehicle CRUD, status transitions, driver assignment.
  2. `DriverApiClient`: Driver roster, availability filtering, CRUD.
  3. `DocumentApiClient`: Compliance document upload, metadata updates, downloads, deletes.
  4. `MaintenanceApiClient`: Maintenance logging, cost updates, workshop history.
  5. `DashboardApiClient`: Real-time telemetry and KPI aggregation.

### Consequences
- **Positive**: Smooth user experience on page refreshes with zero authentication loss.
- **Positive**: Zero coupling between unrelated API calls; clean separation of presentation and network logic.
- **Positive**: 100% testable via unit and widget tests without network calls.
