# Stark Group VMS - Public Home Page & User Registration

**Repository:** `17324Mahir/vms-frontend`  
**Live Frontend:** [https://vms-frontend-stark.netlify.app](https://vms-frontend-stark.netlify.app)  
**Live Backend:** [https://vms-backend-i7bt.onrender.com](https://vms-backend-i7bt.onrender.com)  

---

## 1. Route Architecture

| Route | Access | Component | Purpose |
| :--- | :--- | :--- | :--- |
| `/` | **Public** | `HomeScreen` | Business landing page, capabilities, workflow overview, live status, and CTAs |
| `/login` | **Public** | `LoginScreen` | Authenticate with existing email/password; links to Home and Register |
| `/register` | **Public** | `RegisterScreen` | Create account with full name, email, and password; links to Home and Login |
| `/vehicles` | **Protected** | `VehicleListScreen` | Authenticated fleet management table, filters, search, and action guards |
| `/vehicles/new` | **Protected** | `VehicleFormScreen` | Form to register new fleet vehicles (requires JWT) |
| `/vehicles/edit`| **Protected** | `VehicleFormScreen` | Form to update existing vehicles (requires JWT) |

### Route Guard Enforcement
* Visiting any protected internal route (`/vehicles`, `/vehicles/new`, `/vehicles/edit`) without an active in-memory session immediately redirects to `/login`.
* Once authenticated, visiting `/` or `/login` displays an active session badge with an immediate **"Open App"** action.

---

## 2. User Registration Contract

* **Endpoint:** `POST /api/auth/register`
* **Content-Type:** `application/json`
* **Request Payload:**
  ```json
  {
    "name": "Tony Stark",
    "email": "tony@starkgroup.test",
    "password": "Password123"
  }
  ```
* **Validation Rules:**
  * `name`: Required, non-blank, max 120 chars.
  * `email`: Required, valid email format, max 160 chars, normalized to lowercase.
  * `password`: Required, 6 to 72 characters (enforcing algorithm-aware BCrypt limits).
  * Confirm password: Required on frontend client form.
* **Response Status Codes:**
  * `201 Created`: User persisted in PostgreSQL, returns signed Bearer JWT token and user summary.
  * `400 Bad Request`: Field validation error (e.g. malformed email, password < 6 chars).
  * `409 Conflict`: Code `DUPLICATE_EMAIL` if an account with this normalized email already exists.

---

## 3. Session & Security Model

* **Token Format:** HMAC-SHA256 Bearer JWT.
* **Storage:** In-memory only via `AuthService.instance` (never persisted to browser `localStorage` or `sessionStorage` to mitigate XSS exposure).
* **Automatic Expiration & 401 Handling:** Protected requests receiving `401 Unauthorized` centrally invoke `AuthService.instance.handleUnauthorized()`, clearing private cache and redirecting to `/login`.
* **Sign Out:** Immediately wipes in-memory session, resets `sessionNotifier`, clears cached vehicles in `VehicleRepository`, and routes to `/login`.

---

## 4. Test & Build Commands

### Frontend (`vms-frontend`)
```bash
# Static analysis
flutter analyze

# Run all 58 automated unit, widget, and integration tests
flutter test

# Production web build targeting live Render backend
flutter build web --release --no-tree-shake-icons \
  --dart-define=API_BASE_URL=https://vms-backend-i7bt.onrender.com
```

### Backend (`vms-backend`)
```bash
# Run unit & integration test suites
./gradlew test --no-daemon

# Produce standalone executable JAR
./gradlew bootJar --no-daemon
```
