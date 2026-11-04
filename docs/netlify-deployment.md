# Stark Group VMS - Flutter Web Netlify Deployment Guide

This document describes the reproducible build configuration, deployment settings, routing strategy, and environment variables for hosting the Stark Group Vehicle Management System (VMS) Flutter Web frontend on **Netlify**.

---

## 1. Build Specifications & Pinned Tooling

| Parameter | Specification | Notes |
| :--- | :--- | :--- |
| **Flutter Version** | `3.47.5` (channel: `stable`) | Pinned to project version |
| **Dart SDK** | `3.13.4` (constraint: `^3.13.4`) | Embedded with Flutter 3.47.5 |
| **Target OS / Arch** | Linux x86_64 (`x64`) | Netlify Ubuntu CI image |
| **Archive Source** | `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.5-stable.tar.xz` | Official Google Flutter CDN |
| **Archive SHA-256** | `2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb` | Verified prior to extraction |

---

## 2. Netlify Dashboard Configuration

When connecting the frontend repository to Netlify (either via the Netlify Web UI or Netlify CLI), configure the following build settings:

- **Repository:** `vms-frontend` (or your standalone frontend fork/repository)
- **Production Branch:** `main`
- **Base Directory:** (Leave empty / repository root)
- **Build Command:** `./scripts/build_web.sh`
- **Publish Directory:** `build/web`

---

## 3. Environment Variables

Configure the following variable under **Site configuration > Environment variables** in Netlify:

| Variable | Required | Description | Example |
| :--- | :--- | :--- | :--- |
| `API_BASE_URL` | **Yes** | Public HTTPS origin of the Spring Boot backend REST API. Must not contain `/api` subpaths or point to localhost. | `https://api.vms.starkgroup.test` |
| `ALLOW_LOCALHOST` | No | Set to `1` only if deliberately testing localhost builds in ephemeral preview environments. Default: `0`. | `0` |

> [!IMPORTANT]
> `API_BASE_URL` is a compile-time value supplied to `flutter build web` via `--dart-define=API_BASE_URL="$API_BASE_URL"`.
> If you update `API_BASE_URL` in the Netlify dashboard, you **must trigger a new deploy** (`Clear cache and deploy site`) so the new URL is compiled into `main.dart.js`.

---

## 4. Build Script Behavior (`scripts/build_web.sh`)

The tracked build script [`scripts/build_web.sh`](../scripts/build_web.sh) automates the entire CI build:
1. **Validates Environment:**
   - Verifies that `API_BASE_URL` is non-empty.
   - Rejects `localhost` / `127.0.0.1` origins in production to prevent broken deployments.
   - Enforces valid `http://` or `https://` URI schemes.
   - Normalizes trailing slashes.
2. **SDK Provisioning & Checksum Verification:**
   - Checks if Flutter `3.47.5` is available on the machine.
   - On Netlify (Linux x86_64), downloads the official pinned archive if not cached.
   - Computes and verifies the SHA-256 hash (`2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb`).
   - Extracts the SDK into `.flutter-sdk/` (excluded from git) and adds its `bin` to `PATH`.
3. **Dependency Resolution:**
   - Runs `flutter pub get` against the tracked `pubspec.lock`.
4. **Compilation:**
   - Runs `flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL="${API_BASE_URL}"`.
5. **Output Verification:**
   - Validates that `build/web/index.html` was generated.

---

## 5. Routing & Single-Page Application (SPA) Delivery

Configured in [`netlify.toml`](../netlify.toml):

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

- **Hash-based Routing:** The application uses Flutter Web's default hash router (`/#/login`, `/#/vehicles`).
- **Static Asset Preservation:** Netlify redirects without `force = true` serve existing static files (`canvaskit/`, `main.dart.js`, `assets/`, `icons/`, `favicon.png`) directly, falling back to `/index.html` with HTTP 200 only for non-file route requests.
- **Cache Invalidation:** `index.html` is served with `Cache-Control: no-cache, no-store, must-revalidate` so users immediately receive the latest application bundle on updates.

---

## 6. How to Trigger Deployments

1. **Automatic Continuous Deployment:**
   - Every push to the `main` branch on GitHub automatically triggers a Netlify production build.
2. **Manual Re-deploy via Netlify Dashboard:**
   - Navigate to **Deploys** in the Netlify site dashboard.
   - Click **Trigger deploy > Clear cache and deploy site**.
3. **Deploy via Netlify CLI:**
   ```bash
   npx netlify deploy --build --prod
   ```

---

## 7. Troubleshooting

| Issue | Cause | Resolution |
| :--- | :--- | :--- |
| `API_BASE_URL environment variable is required` | Environment variable not defined in Netlify dashboard | Add `API_BASE_URL` in Site configuration > Environment variables and rebuild. |
| `API_BASE_URL cannot point to localhost in production` | Production build pointing to `localhost` | Update `API_BASE_URL` to the public HTTPS URL of your deployed backend. |
| `Checksum verification failed` | Incomplete download or corrupted archive | Clear build cache in Netlify and re-run deploy. |
| Blank screen / CanvasKit load failure | Network blocking `unpkg.com` or CDN assets | CanvasKit assets are bundled locally in `build/web/canvaskit/` ensuring self-contained delivery. |
| CORS error on login/API requests | Backend does not allow the Netlify site origin | Update `CORS_ALLOWED_ORIGINS` in your Spring Boot backend configuration to include your Netlify site URL (e.g. `https://<site-name>.netlify.app`). |
