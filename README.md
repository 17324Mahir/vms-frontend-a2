# Stark Group VMS - Frontend

Frontend application for the **Stark Group Vehicle Management System (VMS)**, built with **Flutter Web** (Material 3) and connected to the Spring Boot REST API.

---

## 1. Features

- **Authentication:** Professional login screen with in-memory JWT token storage, reactive session state, route guards, and auto-logout on 401.
- **Fleet Registry:** Paginated vehicle list with search by vehicle number, brand, and model, filtering by company and status, and responsive summary stats cards.
- **Vehicle Registration & Editing:** Clean, validated forms with client-side length/format constraints and inline display of server validation/conflict errors (e.g. duplicate vehicle numbers).
- **Vehicle Deletion:** Confirmation dialogs preventing accidental deletions, with instant UI removal upon HTTP 204.
- **Responsive Layout:** Adaptive UI supporting desktop wide screens, tablets, and mobile viewports.
- **Netlify Ready:** Self-contained CI build script (`scripts/build_web.sh`) downloading pinned Flutter SDK with SHA-256 verification and SPA rewrite configuration (`netlify.toml`).

---

## 2. Prerequisites

- **Flutter SDK:** `3.47.5` (channel: `stable`)
- **Dart SDK:** `^3.13.4`
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
  flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=https://api.vms.example.com
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
./scripts/build_web.sh
```
Output directory: `build/web/`

---

## 7. Associated Backend Repository

The Spring Boot REST backend is maintained in:
- **vms-backend:** [https://github.com/17324Mahir/vms-backend](https://github.com/17324Mahir/vms-backend)
