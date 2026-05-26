# MechMate

[![CI](https://github.com/Sashanth-Sekar/mechmate-app/actions/workflows/ci.yml/badge.svg)](https://github.com/Sashanth-Sekar/mechmate-app/actions/workflows/ci.yml)

MechMate is a Flutter app for vehicle owners and mechanics. It supports Android,
iOS, desktop targets, and a browser-based Flutter Web build, with a NestJS
backend API.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Backend Setup](#backend-setup)
- [Flutter Setup](#flutter-setup)
- [Docker](#docker)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool     | Version   | Notes                                    |
| -------- | --------- | ---------------------------------------- |
| Node.js  | >= 20     | Required for the NestJS backend          |
| npm      | >= 10     | Comes with Node.js                       |
| Flutter  | >= 3.27   | Required for the mobile/web app          |
| Dart     | >= 3.6    | Comes with Flutter                       |
| Docker   | >= 24     | Optional — for running Redis & Postgres  |

Verify your versions:

```sh
node --version    # v20+
npm --version     # v10+
flutter --version # 3.27+
```

---

## Backend Setup

The backend is a [NestJS](https://nestjs.com/) API server using TypeORM with
SQLite by default (PostgreSQL in production).

### 1. Environment Configuration

The project ships with a pre-configured `.env` file at `backend/.env`. For a
fresh setup, copy the template:

```sh
cd backend
cp .env.example .env
```

Key variables in `.env`:

| Variable               | Default         | Description                              |
| ---------------------- | --------------- | ---------------------------------------- |
| `PORT`                 | `4001`          | Backend server port                      |
| `NODE_ENV`             | `development`   | Environment mode                         |
| `DATABASE_TYPE`        | `better-sqlite3`| Use `better-sqlite3` for dev, `postgres` for prod |
| `DATABASE_DATABASE`    | `data/mechmate.db` | Path to SQLite database file         |
| `JWT_SECRET`           | _(auto)_        | Secret key for JWT token signing         |
| `FIREBASE_PROJECT_ID`  | `mechmate-production` | Firebase project ID                |

> **Note:** The Flutter app's `AppConfig.apiBaseUrl` points to
> `http://localhost:4001/api/v1`. Make sure the backend port matches.

### 2. Install Dependencies

```sh
cd backend
npm install
```

### 3. Start the Backend

**Development mode** (with hot-reload):

```sh
npm run start:dev
```

The server starts at `http://localhost:4001`. The database file is auto-created at `backend/data/mechmate.db`.

**Production mode:**

```sh
npm run build
npm run start:prod
```

**Debug mode:**

```sh
npm run start:debug
```

### 4. Seed the Database (Optional)

Populate the database with sample workshops, services, and users:

```sh
npm run seed
```

### 5. Verify the Backend

Check that the API responds:

```sh
curl -s -o /dev/null -w "%{http_code}" http://localhost:4001/api/v1/vehicles
# Returns 401 (Unauthorized) — this is expected, since the endpoint requires a JWT.
```

A `401 Unauthorized` response means the server is running correctly. The
`/api/docs` endpoint should also be reachable for Swagger UI.

---

## Flutter Setup

### 1. Install Dependencies

```sh
flutter pub get
```

### 2. Run the App

**On a connected device / emulator:**

```sh
flutter run
```

**Web build (static site):**

```sh
flutter config --enable-web
flutter pub get
flutter build web --release
```

The generated website is in `build/web`.

For a local browser preview after building:

```sh
dart tool/serve_web.dart --port 8080
```

Then open `http://localhost:8080`.

Firebase Hosting is already configured to serve `build/web` with SPA rewrites:

```sh
firebase deploy --only hosting
```

### 3. Run All Tests

```sh
# Flutter tests
flutter test

# Backend tests
cd backend && npm test
```

---

## Docker

A `docker-compose.yml` is provided to run the full stack with PostgreSQL and
Redis:

```sh
docker compose up -d
```

This starts:
- **PostgreSQL** on port `5432`
- **Redis** on port `6379`
- **NestJS Backend** on port `3000` (inside container)

> **Note:** When using Docker, the backend runs on port `3000` inside the
> container. Update `lib/core/constants/app_constants.dart` accordingly if
> running the Flutter app against the Docker backend:
> ```dart
> static const String apiBaseUrl = 'http://localhost:3000/api/v1';
> ```

To tear down:

```sh
docker compose down
```

---

## API Documentation

Once the backend is running, interactive Swagger documentation is available at:

> **http://localhost:4001/api/docs**

This provides a full list of endpoints, request/response schemas, and the
ability to test API calls directly from the browser.

### Available Modules

| Module         | Prefix              | Auth Required |
| -------------- | ------------------- | ------------- |
| Auth           | `/api/v1/auth`      | Some endpoints |
| Users          | `/api/v1/users`     | ✅ Yes        |
| Vehicles       | `/api/v1/vehicles`  | ✅ Yes        |
| Workshops      | `/api/v1/workshops` | ✅ Yes        |
| Bookings       | `/api/v1/bookings`  | ✅ Yes        |
| Mechanics      | `/api/v1/mechanics` | ✅ Yes        |
| Services       | `/api/v1/services`  | ✅ Yes        |
| Notifications  | `/api/v1/notifications` | ✅ Yes     |
| Chat           | WebSocket           | ✅ Yes        |
| Admin          | `/api/v1/admin`     | ✅ Yes        |

---

## Troubleshooting

### Backend fails to start on port 4001

```sh
# Check if something is already using the port
netstat -ano | findstr :4001

# Kill the process (replace PID with the actual process ID)
taskkill /PID <PID> /F
```

### "connect ECONNREFUSED ::1:4001" in Flutter app

The app is trying to reach the backend but it's not running. Make sure you have
started the backend with `npm run start:dev` **before** launching the Flutter
app.

### CORS errors in the Flutter web app

The backend has CORS enabled with `origin: *` by default. If you see CORS
errors, check the `app.enableCors()` configuration in `backend/src/main.ts`.

### Backend database issues

```sh
# Delete the SQLite database to start fresh
rm backend/data/mechmate.db
# Then restart the backend (it will recreate the DB with synchronize: true)
npm run start:dev
```

### Flutter analyze warnings

There are ~40 `withOpacity` deprecation warnings (info level) across the
codebase. These do not affect functionality and will be addressed in a future
migration to `withValues(alpha:)`.


