# Architecture Decision Record (ADR-004)
## Non-Functional Requirements (NFR) & Quality Attributes Strategy

### Status
**ACCEPTED** - Implemented in Assignment 2

### Context
Enterprise systems must not only fulfill functional requirements (CRUD, documents, maintenance) but must excel in six core architectural quality attributes: **Scalability**, **Availability**, **Performance**, **Security**, **Maintainability**, and **Reliability**.

### Quality Attributes & Architectural Solutions

| Quality Attribute | Architectural Solution | Implementation Details |
|:---|:---|:---|
| **Scalability** | • Stateless JWT authentication<br>• High-efficiency connection pooling<br>• Server-side pagination & filtering<br>• Query optimization | • No server session state; horizontal scaling ready.<br>• HikariCP tuned for high throughput.<br>• Pageable queries in Spring Data JPA.<br>• Compound DB indexes on query predicates. |
| **Availability** | • Health check probes<br>• Graceful error degradation<br>• Resilient client retry mechanisms<br>• Circuit breaking patterns | • Spring Boot Actuator `/actuator/health` probes (liveness & readiness enabled).<br>• Frontend displays retry banners with preserved form state on network timeout.<br>• Non-blocking asynchronous daemon processes. |
| **Performance** | • Direct SQL aggregate projections<br>• Compound B-Tree database indexing<br>• Debounced user search<br>• Pure vector asset graphics | • DB calculates `COALESCE(SUM(m.cost), 0)` rather than streaming entities into memory.<br>• Indices on `(user_email, vehicle_number)`, `(user_email, license_number)`, `(vehicle_id, expiry_date)`, `(vehicle_id, maintenance_date)`.<br>• Frontend debouncing minimizes network chatter.<br>• Zero image asset latency using code-drawn vector logo. |
| **Security** | • Defense-in-depth authorization<br>• Strict row-level data isolation<br>• Cryptographic hashing (BCrypt)<br>• Automated CI/CD guardrails | • Spring Security OAuth2 Resource Server validating JWT HMAC-SHA256.<br>• Multi-tenant user scoping on every repository query.<br>• BCrypt password hashing (cost factor 10).<br>• Restricted CORS allowed origins.<br>• Automated GitHub Actions security scans. |
| **Maintainability** | • Clean Layered Architecture<br>• SOLID Principles enforcement<br>• Strong static typing & linting<br>• Comprehensive ADR documentation | • Explicit layers: Controller $\rightarrow$ Service Interface $\rightarrow$ Service Implementation $\rightarrow$ Repository $\rightarrow$ Entity.<br>• Zero circular dependencies.<br>• Strict linting with `flutter analyze` and `gradle check`.<br>• Self-documenting code with meaningful types. |
| **Reliability** | • Transactional consistency (`@Transactional`)<br>• Relational integrity constraints<br>• Test-Driven Development (TDD)<br>• Automated regression gating | • Atomic operations (e.g. vehicle status transition upon maintenance logging).<br>• Foreign key cascading prevents orphaned records.<br>• 100% test pass rate across backend (74 tests) and frontend (74 tests). |

### Monitoring & Telemetry
- Actuator endpoint exposed at `/actuator/health` providing database connectivity, disk space, and application liveness status.
- Telemetry cards on Dashboard surface operational status and real-time alerts.
