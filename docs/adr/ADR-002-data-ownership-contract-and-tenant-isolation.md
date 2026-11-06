# Architecture Decision Record (ADR-002)
## Data Ownership Contract & Multi-Tenant Row-Level Isolation

### Status
**ACCEPTED** - Implemented in Assignment 2

### Context
In enterprise fleet management, multiple organizational divisions or operators utilize the system. Allowing User A to view, edit, or delete vehicles, drivers, documents, or maintenance expenditures belonging to User B represents a critical security vulnerability and a violation of tenant data privacy contracts.

### Decision
We implement a **Strict Row-Level Ownership Contract** enforced across database constraints, service boundaries, and security filters:

```
┌────────────────────────────────────────────────────────┐
│               INCOMING HTTP REQUEST                    │
│   Authorization: Bearer <jwt-with-subject-email>       │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│      JwtAuthenticationToken / SecurityContext          │
│   Extracts and normalizes authenticated principal:      │
│   userEmail = SecurityUtils.getCurrentUserEmail()      │
└───────────────────────────┬────────────────────────────┘
                            │ (Trust boundary: client cannot override)
┌───────────────────────────▼────────────────────────────┐
│                  SERVICE LAYER CONTRACT                │
│                                                        │
│ • findByIdAndUserEmailIgnoreCase(id, userEmail)        │
│ • If not found or mismatch: throw 404 VehicleNotFound   │
│ • No entity modification permitted without ownership   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                PERSISTENCE LAYER CONTRACT              │
│                                                        │
│ • WHERE LOWER(v.user_email) = LOWER(:userEmail)        │
│ • UNIQUE(user_email, vehicle_number)                   │
│ • UNIQUE(user_email, license_number)                   │
└────────────────────────────────────────────────────────┘
```

#### 1. Invariable Principal Extraction
- The user's identity is derived strictly from the cryptographically verified JWT token claims:
  ```java
  String userEmail = SecurityUtils.getCurrentUserEmail();
  ```
- No client-supplied query parameter, body attribute, or custom header can override or spoof this tenant ownership.

#### 2. Service-Level Ownership Enforcing
- **Vehicle Retrieval & Mutation**: All `findById` calls require `findByIdAndUserEmailIgnoreCase(id, userEmail)`. Cross-tenant queries return `404 Not Found` to prevent entity enumeration.
- **Document Management**: Every document fetch (`GET /api/documents/{id}` or `/download`) verifies `doc.getVehicle().getUserEmail().equalsIgnoreCase(userEmail)`.
- **Maintenance Records**: Every maintenance fetch or update verifies `record.getVehicle().getUserEmail().equalsIgnoreCase(userEmail)`.
- **Driver Management**: All driver queries enforce `user_email = :userEmail`.

#### 3. Database Integrity Constraints
- Vehicles: `uk_vehicles_user_vehicle_number (user_email, vehicle_number)`
- Drivers: `uk_drivers_user_license_number (user_email, license_number)`
- Indices on `user_email` guarantee high-performance query execution and scalable tenant isolation.

### Consequences
- **Positive**: Complete defense-in-depth isolation preventing Horizontal Privilege Escalation (IDOR).
- **Positive**: Multi-tenancy achieved without complex separate database architectures or schema-per-tenant overhead.
- **Verification**: Covered by automated TDD integration tests specifically testing cross-tenant access rejection.
