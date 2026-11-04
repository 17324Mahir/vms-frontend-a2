# Stark Group VMS End-to-End Verification Report

## 1. Overview and Environment

- **Date:** November 3, 2026
- **Tested Revision / Commit:** `d76d21905baf08bda49aed8fef916db0452ba21e`
- **Frontend URL:** `http://localhost:5173` (Flutter Web release build)
- **Backend API URL:** `http://localhost:8080` (Spring Boot 3.4.3 / Java 26)
- **Database:** PostgreSQL 14+ on `localhost:5432` (`stark_vms_db`, user `vms_user`)
- **Browser Automation:** Headless Google Chrome (`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`) driven via Puppeteer Core exercising real CanvasKit semantics, keyboard input, mouse coordinates, and navigation events.

---

## 2. Launch Commands Used for Each Tier

### 2.1 Database
```bash
brew services start postgresql@14
# Verified connection
psql -U vms_user -d stark_vms_db -c "SELECT current_database(), current_user;"
```

### 2.2 Spring Boot Backend
```bash
cd backend
DB_URL="jdbc:postgresql://localhost:5432/stark_vms_db" \
DB_USERNAME="vms_user" \
DB_PASSWORD="" \
JWT_SECRET="super-secret-key-that-is-at-least-32-bytes-long-for-hmac!" \
COURSE_USER_EMAIL="test@starkgroup.test" \
COURSE_USER_PASSWORD_HASH='$2a$10$zfYD.tKC4HUNa59nE9UIReikpP660ZT5Yg.nkmbkpEk./PCUyupC2' \
CORS_ALLOWED_ORIGINS="http://localhost:5173" \
./gradlew bootRun --no-daemon
```

### 2.3 Flutter Web Frontend
```bash
# Build release bundle targeting live backend
flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=http://localhost:8080

# Serve static web distribution on port 5173
python3 -m http.server 5173 --directory build/web
```

---

## 3. End-to-End Verification Scenarios

| Scenario | Expected result | Actual result | Status | Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **Stack startup** | Backend and database healthy; frontend reachable at :5173; CORS configured | Actuator UP (db: PostgreSQL); frontend HTTP 200; CORS preflight allows `http://localhost:5173` | Pass | `curl http://localhost:8080/actuator/health` -> `{"status":"UP","components":{"db":{"status":"UP",...}}}`; OPTIONS `/api/vehicles` returns `Access-Control-Allow-Origin: http://localhost:5173` |
| **Protected access** | Unauthenticated route access redirects to Login; raw API access returns 401 | Navigating to `/#/vehicles` redirected to Login screen; GET `/api/vehicles` returned 401 | Pass | Route guard active; [01_protected_route_redirect.png](screenshots/01_protected_route_redirect.png); raw API returns HTTP 401 |
| **Invalid login** | Submitting invalid credentials displays clear generic alert and denies access | Displayed "Email or password is incorrect."; no session established | Pass | POST `/api/auth/login` returned 401 `INVALID_CREDENTIALS`; [02_invalid_login_error.png](screenshots/02_invalid_login_error.png) |
| **Valid login** | Authenticates course user, stores in-memory token, and loads Vehicle List | Backend returned 200 OK with Bearer token; navigated to Fleet Registry showing `test@starkgroup.test` | Pass | POST `/api/auth/login` returned 200; [03_valid_login_fleet_list.png](screenshots/03_valid_login_fleet_list.png) |
| **Vehicle list** | Requests real backend data; displays genuine empty state when database has 0 records | UI displays genuine empty state ("No vehicles registered", "Total: 0 vehicles"); SQL confirms 0 records | Pass | GET `/api/vehicles` returned 200 OK with `[]`; SQL `SELECT count(*) FROM vehicles` = 0 |
| **Register** | Submits valid payload, returns 201 Created with Location header, vehicle appears in UI and SQL | Vehicle `STK-E2E-1001` appears in UI list (Total: 1 vehicles); SQL row created with ID 88 (`Stark Logistics`, `Lockheed`, `F-35`, `ACTIVE`) | Pass | POST `/api/vehicles` returned 201; SQL row: `88\|STK-E2E-1001\|Stark Logistics\|Lockheed\|F-35\|ACTIVE`; [04_register_form_filled.png](screenshots/04_register_form_filled.png), [05_vehicle_created_in_list.png](screenshots/05_vehicle_created_in_list.png) |
| **Persistence after refresh** | Reload resets in-memory token; after authenticating, persisted vehicle reloads from backend | Session reset to Login as designed; upon signing in, `STK-E2E-1001` reloaded from PostgreSQL | Pass | In-memory token security confirmed; backend GET `/api/vehicles` returned persistent record; [06_persistence_after_refresh.png](screenshots/06_persistence_after_refresh.png) |
| **Update** | Saves modified model, preserves existing ID without duplicating row, updates UI and SQL | UI displays "F-35 Lightning II"; SQL model updated to "F-35 Lightning II"; total row count remains 1 | Pass | PUT `/api/vehicles/88` returned 200 OK; SQL row updated in place; [07_edit_form_modified.png](screenshots/07_edit_form_modified.png), [08_vehicle_updated_in_list.png](screenshots/08_vehicle_updated_in_list.png) |
| **Cancel delete** | Delete dialog identifies vehicle number; clicking Keep Vehicle aborts deletion with no DELETE request | Confirmation opened for `STK-E2E-1001`; Cancel clicked; 0 DELETE requests sent; SQL record preserved | Pass | No DELETE API call made; SQL count remains 1; [09_delete_confirmation_dialog.png](screenshots/09_delete_confirmation_dialog.png) |
| **Confirm delete** | Dispatches DELETE request, removes record from fleet table, and removes row from PostgreSQL | Record removed from UI; fleet total back to 0; SQL `SELECT count(*)` confirms 0 rows | Pass | DELETE `/api/vehicles/88` returned 204 No Content; SQL count = 0; [10_vehicle_deleted_empty_list.png](screenshots/10_vehicle_deleted_empty_list.png) |
| **Duplicate create** | Rejects duplicate registration with 409 Conflict; displays inline error; preserves form data; inserts 0 extra rows | Server returned 409 `DUPLICATE_VEHICLE_NUMBER`; form preserved values (`Tesla Duplicate`, `Model Y`); SQL count for `STK-E2E-2001` remains 1 | Pass | POST `/api/vehicles` returned 409 Conflict; SQL count = 1; [11_duplicate_create_error.png](screenshots/11_duplicate_create_error.png) |
| **Duplicate update** | Attempting to update vehicle B to vehicle A number returns 409 Conflict; both DB rows unchanged | Server returned 409 `DUPLICATE_VEHICLE_NUMBER`; SQL records `STK-E2E-2001` and `STK-E2E-2002` remain unchanged | Pass | PUT `/api/vehicles/{id}` returned 409 Conflict; SQL rows verified intact; [12_duplicate_update_error.png](screenshots/12_duplicate_update_error.png) |
| **Invalid input** | Validates mandatory fields and string length client-side; blocks submit; shows inline errors | Displayed "Vehicle Number is required." and "cannot exceed 64 characters"; 0 requests sent | Pass | Client validation active; 0 requests sent to backend; [13_invalid_input_validation.png](screenshots/13_invalid_input_validation.png) |
| **Sign-out** | Clears in-memory session and cached fleet state; navigates back to Login screen; blocks re-entry | Session cleared; returned to Login screen; route guard blocks re-entry to `/#/vehicles` | Pass | `AuthService.signOut()` cleared tokens and vehicle cache; [14_sign_out_login_screen.png](screenshots/14_sign_out_login_screen.png) |
| **Test-data cleanup** | Safely removes all E2E test records without resetting tables or affecting unrelated data | All E2E vehicles deleted; PostgreSQL vehicles count = 0 | Pass | SQL `DELETE FROM vehicles WHERE vehicle_number LIKE 'STK-E2E-%'`; final `SELECT count(*)` = 0 |

---

## 4. Verification Suite Results

### 4.1 Frontend Verification
- `flutter analyze`: **0 issues found** (Clean)
- `flutter test`: **53 / 53 passed** (100% success across all unit, widget, and workflow tests)

### 4.2 Backend Verification
- `./gradlew test --rerun --no-daemon`: **66 / 66 passed** (0 failures, 0 skipped across all controller, service, repository, and auth tests)
- `./gradlew build -x test --no-daemon`: **BUILD SUCCESSFUL**

### 4.3 Database Cleanup
- `SELECT count(*) FROM vehicles WHERE vehicle_number LIKE 'STK-E2E-%';` -> `0`
- `SELECT count(*) FROM vehicles;` -> `0` (Initial pristine state restored)
