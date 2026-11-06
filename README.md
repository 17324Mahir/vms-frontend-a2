# Stark Group VMS - Frontend (Assignment 2 Fleet Management)

Frontend application for the **Stark Group Vehicle Management System (VMS)**, with a **Next.js** public landing page and a **Flutter Web** workspace connected to the Spring Boot REST API.

---

## 1. Assignment 2 Features & Extensions

1. **Vehicle Document Upload & Storage:** Support for Registration, Tax Token, Insurance, Fitness Certificate, and other documents with file upload support.
2. **Document Expiry Tracking:** Real-time expiry alerts with calculated days until expiry (`EXPIRED`, `EXPIRING_SOON`, `VALID` badges).
3. **Vehicle Maintenance Management:** Logging service records with date, service type, cost, workshop/vendor, and odometer reading.
4. **Maintenance History Ledger:** Chronological service records for each vehicle with aggregated lifetime spend.
5. **Vehicle Lifecycle Status Management:** Immediate status updates across `ACTIVE`, `INACTIVE`, and `MAINTENANCE` states.
6. **Multi-Field Vehicle Search:** Server-side search by Vehicle Number, Brand, Model, Company, and Driver.
7. **Server-Side Pagination & Sorting:** Paginated vehicle list handling large enterprise datasets.
8. **Driver Directory & Management:** Complete Driver CRUD with duplicate license number validation, license expiry tracking, and status indicator (`AVAILABLE`, `ASSIGNED`, `SUSPENDED`).
9. **Driver–Vehicle Assignment:** Dynamic driver assignment and unassignment with automatic driver status updates.
10. **Fleet Dashboard & Analytics:** High-level executive KPIs (total vehicles, active/maintenance/inactive breakdown, registered drivers, lifetime maintenance cost, and urgent renewal notices).

---

## 2. Prerequisites

- **Flutter SDK:** `3.47.5` (channel: `stable`)
- **Dart SDK:** `^3.13.4`
- **Node.js:** `24` for the landing page build
- **Supported Browser:** Google Chrome, Chromium, Firefox, Edge, or Safari

Verify your Flutter installation:
```bash
flutter --version
flutter doctor
```

---

## 3. Dependency Installation

Resolve Flutter packages:
```bash
flutter pub get
```

---

## 4. Development Startup

To run the web application locally during development:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

---

## 5. API_BASE_URL Configuration & CORS

The application reads the target backend origin at compile time via `String.fromEnvironment('API_BASE_URL')`.

- **Development:** Default is `http://localhost:8080`.
- **Production:** Provide your public HTTPS backend origin:
  ```bash
  API_BASE_URL=https://vms-backend-a2.onrender.com ./scripts/build_web.sh
  ```
- **Backend CORS:** The backend must include your frontend origin in its `CORS_ALLOWED_ORIGINS` configuration (e.g. `http://localhost:5173` or `https://<site>.netlify.app`).

---

## 6. Testing & Building

### Run Static Analysis
```bash
flutter analyze
```

### Run Automated Tests (Unit, Widget, Workflow)
```bash
flutter test
```

### Build Production Web Release Bundle
```bash
API_BASE_URL=https://vms-backend-a2.onrender.com ./scripts/build_web.sh
```
Publish `build/web/`. The landing page is served at `/` and the Flutter workspace at `/workspace.html`. GitHub Actions and Netlify use this same build script.

---

## 7. Associated Backend Repository

The Spring Boot REST backend is maintained in:
- **vms-backend-a2:** [https://github.com/17324Mahir/vms-backend-a2](https://github.com/17324Mahir/vms-backend-a2)
