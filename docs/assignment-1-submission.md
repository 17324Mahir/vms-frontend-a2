# Assignment 1 Submission: Rebuild the Stark Group VMS

**Course Assignment Reference:** [Assignment Document](https://docs.google.com/document/d/1IUtFRW1n8dfIYsHRAA9jgtvK15nQvm12/edit)
**Submission Date:** November 4, 2026
**Final Status:** Ready to Submit

---

## 1. Project Description

The Stark Group Vehicle Management System (VMS) is a modern, enterprise-grade fleet management solution built for the subsidiaries of the Stark Group. The application provides secure fleet registry operations, full vehicle lifecycle management (Create, Read, Update, Delete), duplicate vehicle number enforcement, robust client/server validation, and responsive cross-device layouts.

The system is deployed as two independent production services:
- **Frontend:** Flutter Web application compiled with CanvasKit and hosted on Netlify Edge CDN.
- **Backend:** Java Spring Boot REST API containerized with Docker and hosted on Render Web Services, backed by a managed PostgreSQL 16 database.

---

## 2. Technology Stack

- **Frontend:** Flutter 3.38.5 (Web / CanvasKit renderer), Dart 3.10.7, GoRouter (Declarative Routing & Route Guards), Provider / ValueNotifier state management, Material 3 Stark theme.
- **Backend:** Java 21, Spring Boot 3.4.3, Spring Security 6 (Stateless JWT / OAuth2 Resource Server via Nimbus), Spring Data JPA, Hibernate 6, Flyway migrations, Gradle 9.3.1.
- **Database:** PostgreSQL 16 (Render Managed Database).
- **Production Hosting:** Netlify (Frontend) and Render (Backend & Database).

---

## 3. Verified Link Register

| Item | Actual URL | Verification Result |
| :--- | :--- | :--- |
| **Live VMS Frontend** | `https://vms-frontend-stark.netlify.app` | Verified live; HTTP 200 OK; SSL HTTPS active; CanvasKit assets loaded |
| **Frontend GitHub Repository** | `https://github.com/17324Mahir/vms-frontend` | Verified public repository; branch `main`; clean status |
| **Backend GitHub Repository** | `https://github.com/17324Mahir/vms-backend` | Verified public repository; branch `main`; clean status |
| **Production API Base URL** | `https://vms-backend-i7bt.onrender.com` | Verified live; HTTPS active; CORS configured for Netlify origin |
| **Public Health Endpoint** | `https://vms-backend-i7bt.onrender.com/actuator/health` | Verified live; HTTP 200 `{"status":"UP","groups":["liveness","readiness"]}` |
| **Frontend README** | `https://github.com/17324Mahir/vms-frontend#readme` | Verified tracked and pushed in repository root |
| **Backend README** | `https://github.com/17324Mahir/vms-backend#readme` | Verified tracked and pushed in repository root |
| **API Documentation** | `https://github.com/17324Mahir/vms-backend/blob/main/docs/api-documentation.md` | Comprehensive endpoint contracts, payloads, and response codes |
| **Test / E2E Evidence** | `https://github.com/17324Mahir/vms-frontend/blob/main/docs/live-verification.md` | 16/16 automated live scenarios passed with captured screenshots |
| **Final Frontend Commit** | `4acbec2a921489009fd246dea16347eed2b1ee26` | Deployed and verified on Netlify |
| **Final Backend Commit** | `333a936c21fe8c1fdc589e4d9f037844624fdea4` | Deployed and live on Render |
| **Course Assignment Doc** | `https://docs.google.com/document/d/1IUtFRW1n8dfIYsHRAA9jgtvK15nQvm12/edit` | Assignment reference document |

---

## 4. Secure Evaluator-Login Instructions

The deployed Stark Group VMS enforces stateless, cryptographically signed JWT Bearer authentication. For academic evaluation:

1. Navigate to the live application: **`https://vms-frontend-stark.netlify.app`**
2. An unauthenticated visit immediately redirects to the Login screen (`/#/login`).
3. Enter the designated course evaluator credentials:
   - **Evaluator Email:** `test@starkgroup.test`
   - **Password:** *Available in the private course submission form / evaluator notes. Never committed to public version control.*
4. Click **Sign in**. Upon authentication:
   - The backend validates credentials and issues an HMAC-SHA256 signed JWT.
   - The frontend stores the token strictly in-memory (preventing XSS persistence attacks) and navigates to the Fleet Registry (`/#/vehicles`).
   - All subsequent HTTP requests attach the token as an `Authorization: Bearer <token>` header.
5. In accordance with zero-trust session security, refreshing the browser clears in-memory tokens and redirects to Login; re-authenticating reloads all persisted fleet records directly from PostgreSQL.

---

## 5. Requirement Verification Checklist

| Requirement | Implemented Code | Relevant Test / Verification | Actual Result | Status | Remaining Issue |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Login Functionality** | `LoginScreen`, `AuthService`, `AuthController` | `auth_service_test.dart`, `AuthControllerTest.java` | Authenticates course account, issues JWT Bearer token, displays error on invalid password | **Pass** | None |
| **Vehicle List** | `VehicleListScreen`, `VehicleRepository`, `VehicleController.getAllVehicles` | `vehicle_ui_integration_test.dart`, `VehicleControllerIntegrationTest.java` | Renders paginated registry loaded from Render PostgreSQL | **Pass** | None |
| **Add / Register Vehicle** | `VehicleFormScreen`, `VehicleApiClient.createVehicle`, `VehicleService.createVehicle` | `vehicle_crud_workflow_test.dart`, `VehicleServiceTest.java` | Submits valid payload, returns 201 Created with Location header, displays in UI | **Pass** | None |
| **Edit Vehicle** | `VehicleFormScreen`, `VehicleApiClient.updateVehicle`, `VehicleService.updateVehicle` | `vehicle_crud_workflow_test.dart`, `VehicleControllerTest.java` | Updates existing record in-place preserving primary key ID; returns 200 OK | **Pass** | None |
| **Delete Vehicle** | `ConfirmationDialog`, `VehicleApiClient.deleteVehicle`, `VehicleService.deleteVehicle` | `widget_test.dart`, `VehicleControllerTest.java` | Prompts confirmation; Keep Vehicle preserves record; Confirm dispatches DELETE, returns 204 No Content | **Pass** | None |
| **Flutter Web Frontend** | `lib/` root, `AppShell`, `AppRouter`, CanvasKit build | `scripts/build_web.sh`, Netlify deploy | Fully responsive UI across Desktop, Tablet, and Mobile viewports; 0 console errors | **Pass** | None |
| **Java Spring Boot Backend** | `src/main/java/com/starkgroup/vms/`, Spring Boot 3.4.3 | `./gradlew test --no-daemon`, Render deploy | Dockerized Spring Boot service running on port 8080 (Render dynamic port) | **Pass** | None |
| **SQL Database** | Render PostgreSQL 16, Spring Data JPA / Hibernate | `psql` verification, integration tests | Real PostgreSQL persistence; all vehicle records stored in `vehicles` table | **Pass** | None |
| **REST API Integration** | `VehicleApiClient` (http client), `VehicleController` | Automated browser E2E, mock integration tests | Live HTTP calls connecting Netlify frontend to Render REST endpoints | **Pass** | None |
| **Duplicate Vehicle Number Validation** | `VehicleServiceImpl.java`, `DuplicateVehicleNumberException`, `GlobalExceptionHandler` | `VehicleServiceTest.java`, live verification script | Case-insensitive & trimmed duplicate checks reject duplicate with 409 Conflict; form inputs preserved | **Pass** | None |
| **Real Database-Backed Data** | `VehicleRepository.java`, `VehicleRepository.dart` | Live E2E database query checks | Zero mock fallback; UI state is 100% sourced from and synchronized with Render PostgreSQL | **Pass** | None |

---

## 6. Test and Build Verification Results

### Frontend Verification
- **Static Analysis:** `flutter analyze` executed with **0 issues found** (ran in 2.1s).
- **Automated Tests:** `flutter test` executed with **53 / 53 passed** (ran in 6s), covering authentication, route guards, token attachment, form validation, error handling, and responsive layouts.
- **Production Build:** Deterministic CanvasKit bundle produced via `flutter build web --release --dart-define=API_BASE_URL=https://vms-backend-i7bt.onrender.com`.

### Backend Verification
- **Automated Test Suite:** `./gradlew test --no-daemon` executed with **66 / 66 passed** (5 actionable tasks, build time 12s), covering unit tests, duplicate rule tests, controller security integration tests, and PostgreSQL dialect tests.
- **Production Build:** `./gradlew build -x test --no-daemon` successfully assembled `build/libs/vms-backend-0.0.1-SNAPSHOT.jar`.

---

## 7. Live Journey Verification Summary

The live verification script tested 16 end-to-end scenarios against the deployed infrastructure:
1. **Live Stack Health:** Render Actuator `status=UP`; Netlify HTTP 200. (**Pass**)
2. **Protected Access:** Unauthenticated visit to `/#/vehicles` redirected to `/#/login`; raw API returned 401. (**Pass**)
3. **Invalid Login:** Displayed "Email or password is incorrect."; 0 session established. (**Pass**)
4. **Valid Login:** Authenticated course user; received JWT Bearer token; navigated to Fleet Registry. (**Pass**)
5. **Vehicle List Read:** Fleet registry rendered with live data from Render PostgreSQL. (**Pass**)
6. **Register Vehicle:** Created `STK-LIVE-1001` (`Lockheed`, `F-35`); 201 Created; SQL row created with ID 8. (**Pass**)
7. **Persistence After Refresh:** In-memory session cleared on refresh; re-login reloaded `STK-LIVE-1001` from PostgreSQL. (**Pass**)
8. **Update Vehicle:** Updated model to `F-35 Lightning II`; 200 OK; SQL row updated in-place without duplicating. (**Pass**)
9. **Cancel Deletion:** Confirmation dialog showed vehicle number; clicking Keep Vehicle sent 0 DELETE calls; row preserved. (**Pass**)
10. **Confirm Deletion:** Clicking Delete Vehicle sent `DELETE /api/vehicles/8`; returned 204 No Content; row removed from UI and SQL. (**Pass**)
11. **Duplicate Create:** Registering duplicate `STK-LIVE-2001` returned 409 `DUPLICATE_VEHICLE_NUMBER`; form preserved; 0 duplicate SQL rows. (**Pass**)
12. **Duplicate Update:** Renaming `STK-LIVE-2002` to existing `STK-LIVE-2001` returned 409 Conflict; both SQL rows remained intact. (**Pass**)
13. **Invalid Input:** Blank submit triggered required field errors; >64 char input triggered "cannot exceed 64 characters"; 0 network calls sent. (**Pass**)
14. **Responsive Layouts:** Verified non-overflowing, fully functional views on Desktop (1440px), Landscape Tablet (1024px), Portrait Tablet (768px), and Mobile (390px). (**Pass**)
15. **Sign-Out:** `AuthService.signOut()` cleared session and cache; returned to Login screen; route guard blocked re-entry. (**Pass**)
16. **Test-Data Cleanup:** Targeted SQL DELETE cleaned all temporary `STK-LIVE-*` test records; final `SELECT count(*)` confirmed 0. (**Pass**)

---

## 8. Known Limitations & Notes

- **Assignment 2 Scope Exclusions:** In accordance with Assignment 1 boundaries, advanced features such as driver assignment, vehicle document uploads, expiry alerts, and maintenance tracking are scheduled for Assignment 2 and are intentionally not present in this submission.
- **Render Free Tier Spin-Down:** Render free-tier web services spin down after 15 minutes of inactivity. When visiting the live frontend after an idle period, the initial API call may take 30–50 seconds while the backend container wakes up. Subsequent calls respond with sub-second latency.

---

## 9. Final Readiness Decision

**Decision: READY TO SUBMIT**

All Assignment 1 functional, architectural, security, deployment, and evidence requirements are complete, verified on the live production stack, and backed by clean, synchronized Git repositories.
