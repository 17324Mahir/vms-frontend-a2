# Architecture Decision Record (ADR-005)
## Automated Security Guardrails & CI/CD Pipeline via GitHub Actions

### Status
**ACCEPTED** - Implemented in Assignment 2

### Context
Manual code review and local-only testing fail to prevent regression bugs, security misconfigurations, or leaked credentials from reaching production branches (`main`). Automated guardrails enforced via continuous integration (CI) ensure every commit is verified against security policies, static code quality standards, and unit/integration tests before deployment.

### Decision
We implement automated GitHub Actions CI/CD pipelines for both repositories (`vms-backend-a2` and `vms-frontend-a2`) serving as automated quality and security guardrails:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          GITHUB ACTIONS CI PIPELINE                    │
│                        Trigger: Push & Pull Request                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
       ┌────────────────────────────┼────────────────────────────┐
       │                            │                            │
┌──────▼─────────────────────┐ ┌────▼─────────────────────┐ ┌────▼─────────────────────┐
│    Static Quality & Lint   │ │  Unit & Integration Tests│ │    Security Guardrails   │
│                            │ │                          │ │                          │
│ • Gradle Check             │ │ • Gradle Test (74 tests) │ │ • Secret Leak Scan       │
│ • Flutter Analyze (0 warn) │ │ • Flutter Test (74 tests)│ │ • Dependency Audit       │
│ • Dart Format Verification │ │ • Multi-Tenant Sec Tests │ │ • Vulnerability Checks   │
│ • Checkstyle / SpotBugs    │ │ • Code Coverage Report   │ │ • Gated Merge Policy     │
└────────────────────────────┘ └──────────────────────────┘ └──────────────────────────┘
```

#### 1. Backend CI Guardrail Pipeline (`.github/workflows/ci.yml` in `vms-backend-a2`)
- **Triggers**: Every `push` and `pull_request` to `main`.
- **Environment**: Ubuntu Latest with OpenJDK 21, Gradle dependency caching.
- **Stage 1 (Code Quality & Build)**: Compiles source and verifies Gradle build cleanliness.
- **Stage 2 (Automated Test Suite)**: Runs all 74 unit, repository, service, and Spring Boot integration tests.
- **Stage 3 (Security Guardrails)**:
  - Scans repository for unencrypted secrets and private keys.
  - Verifies dependency integrity.
  - Enforces fail-fast behavior if any test fails.

#### 2. Frontend CI Guardrail Pipeline (`.github/workflows/ci.yml` in `vms-frontend-a2`)
- **Triggers**: Every `push` and `pull_request` to `main`.
- **Environment**: Ubuntu Latest with Flutter Stable channel, Pub cache.
- **Stage 1 (Code Formatting & Static Analysis)**:
  - `dart format --output=none --set-exit-if-changed .`
  - `flutter analyze --fatal-infos --fatal-warnings`
- **Stage 2 (Automated Test Suite & Coverage)**:
  - `flutter test --coverage`
  - Verifies all 74 unit, model, repository, and widget integration tests pass.
- **Stage 3 (Production Web Build)**:
  - Runs `flutter build web --release` to verify bundle compilation.

### Consequences
- **Positive**: Regressions are blocked before merging into `main`.
- **Positive**: Strict adherence to security hygiene and coding guidelines.
- **Positive**: Provides automated feedback to developers on pull requests.
