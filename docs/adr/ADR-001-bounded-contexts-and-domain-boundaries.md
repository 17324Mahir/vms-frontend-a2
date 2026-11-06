# Architecture Decision Record (ADR-001)
## Bounded Contexts & Domain Segregation in Stark Group VMS

### Status
**ACCEPTED** - Implemented in Assignment 2

### Context
The Stark Group Vehicle Management System (VMS) transitioned from a simple CRUD utility into an enterprise-grade fleet telematics, compliance, and workforce operations platform. Without clearly defined domain boundaries, coupling between identity, vehicle telemetry, driver allocation, document compliance, and financial maintenance led to monolithic entity models and regression risks.

### Decision
We partition the Stark Group VMS architecture into six explicit **Bounded Contexts** following Domain-Driven Design (DDD) principles:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        STARK GROUP VMS ECOSYSTEM                       │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
      ┌──────────────────────────────┼──────────────────────────────┐
      │                              │                              │
┌─────▼──────────────┐     ┌─────────▼──────────┐     ┌─────────────▼──────┐
│  Identity & Access │     │    Fleet Asset     │     │  Driver Workforce  │
│  Management (IAM)  │     │   Lifecycle (VMS)  │     │  Management (DWM)  │
│                    │     │                    │     │                    │
│ • User Accounts    │     │ • Vehicle Reg.     │     │ • Driver Profiles  │
│ • JWT Auth         │◄────┤ • Operational State│◄────┤ • Licensing        │
│ • Password Reset   │     │ • Brand/Model/Comp │     │ • Allocation State │
│ • BCrypt Security  │     │ • Multi-tenant Tag │     │ • Direct Assignment│
└────────────────────┘     └─────────┬──────────┘     └────────────────────┘
                                     │
      ┌──────────────────────────────┼──────────────────────────────┐
      │                              │                              │
┌─────▼──────────────┐     ┌─────────▼──────────┐     ┌─────────────▼──────┐
│ Compliance & Docs  │     │    Maintenance     │     │  Fleet Telematics  │
│  Vault (CDV)       │     │  Operations (MOP)  │     │  & Dashboard (FTD) │
│                    │     │                    │     │                    │
│ • Statutory Certs  │     │ • Service Records  │     │ • Aggregate KPIs   │
│ • Expiry Tracking  │◄────┤ • Workshop Billing │◄────┤ • Critical Alerts  │
│ • Binary Files     │     │ • Odometer History │     │ • Live Telemetry   │
│ • Alert Windows    │     │ • Cost Aggregation │     │ • Roster Summaries │
└────────────────────┘     └────────────────────┘     └────────────────────┘
```

#### 1. Identity & Access Management (IAM) Context
- **Boundary**: User registration, authentication, JWT token issuance/verification, and password reset workflows.
- **Aggregate Root**: `User`, `PasswordResetToken`
- **Invariants**: Unique email address, BCrypt password hash (cost factor 10), 15-minute OTP expiry.
- **Decoupling**: Provides security principal (`user_email`) downstream without leaking credentials to fleet domains.

#### 2. Fleet Asset Lifecycle Context
- **Boundary**: Physical fleet asset inventory, classification, and operational lifecycle.
- **Aggregate Root**: `Vehicle`
- **Invariants**: Unique `vehicle_number` per tenant; operational states (`ACTIVE`, `INACTIVE`, `MAINTENANCE`).
- **Dependencies**: Soft reference to `Driver` (assignment ID).

#### 3. Driver Workforce Management Context
- **Boundary**: Driver employment, licensing compliance, and vehicle allocation.
- **Aggregate Root**: `Driver`
- **Invariants**: Unique `license_number` per tenant; status lifecycle (`AVAILABLE`, `ASSIGNED`, `ON_LEAVE`).

#### 4. Compliance & Document Vault Context
- **Boundary**: Legal compliance certificates (Registration, Tax Token, Fitness Certificate, Comprehensive Insurance) and binary file archiving.
- **Aggregate Root**: `VehicleDocument`
- **Invariants**: Strict statutory document type constraints; mandatory expiry date; calculation of real-time expiry urgency (`EXPIRED`, `EXPIRING_SOON`, `VALID`).

#### 5. Maintenance Operations Context
- **Boundary**: Workshop servicing, expenditure tracking, odometer milestones, and vehicle status transitions.
- **Aggregate Root**: `MaintenanceRecord`
- **Invariants**: Cost $\ge 0.00$; mandatory workshop/vendor attribution; optional status transition back to `ACTIVE` upon completion.

#### 6. Fleet Telematics & Analytics Context
- **Boundary**: Cross-domain aggregation, compliance monitoring, and operational intelligence.
- **Read Model / Projection**: `DashboardStatsResponse`
- **Invariants**: Aggregates calculated directly in the persistence layer with SQL `COALESCE(SUM(...))` for maximum scalability and zero memory bloat.

### Consequences
- **Positive**: High cohesion within contexts, low coupling across contexts, strict adherence to Single Responsibility Principle (SRP) and Interface Segregation Principle (ISP).
- **Positive**: Individual contexts can be refactored or extracted into independent microservices with minimal cross-domain refactoring.
- **Trade-off**: Requires explicit DTO mapping and service contracts between contexts.
