# Note Management Application

> **Course:** WEB PROGRAMMING & APPLICATIONS — 503073  
> **Midterm topic:** Topic 10 — Containerization & Orchestration (Docker)  
> **Authors:** Bui Chau Hai Dang (524H0148), Ngo Dang Trong Hieu (524H0050)  
> **Instructor:** Dr. Van-Vang Le

A multi-tier note management web application packaged as four isolated Docker services. The stack is started with a single command: `docker compose up`.

---

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [System Architecture](#system-architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start (Docker — recommended)](#quick-start-docker--recommended)
5. [Environment Variables](#environment-variables)
6. [Demo Credentials](#demo-credentials)
7. [Testing Real-time Collaboration](#testing-real-time-collaboration)
8. [Useful Docker Commands](#useful-docker-commands)
9. [Troubleshooting](#troubleshooting)
10. [Local Setup (XAMPP — optional)](#local-setup-xampp--optional)
11. [Application Features](#application-features)
12. [Project Structure](#project-structure)

---

## Technology Stack

| Layer | Technology | Role |
|-------|------------|------|
| **Web tier** | Laravel 12, PHP 8.2, Apache | Server-rendered UI (Blade + Bootstrap 5.3) and REST-style API endpoints |
| **Database** | PostgreSQL 15 (Alpine) | Persistent storage for users, notes, labels, shares |
| **Cache / session** | Redis (Alpine) | Session store and cache (configured in `docker-compose.yml`) |
| **Real-time** | Laravel Reverb | WebSocket server for collaborative note editing |
| **Containerization** | Docker, Docker Compose | Image build, multi-service orchestration, isolated network |

> **Note:** Topic 10 requires Frontend, Backend API, Redis, and PostgreSQL. This project implements them as four containers: `app` combines the Laravel frontend and backend in one web container; `websocket` runs the real-time service separately.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              Docker network: note_network (bridge)              │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐ │
│  │   note_app_web   │  │   note_app_db    │  │ note_app_redis│ │
│  │ Laravel + Apache │  │  PostgreSQL 15   │  │     Redis     │ │
│  │   host :8000     │  │ host :5433→5432  │  │  host :6379   │ │
│  └────────┬─────────┘  └─────────────────┘  └───────────────┘ │
│           │                                                     │
│  ┌────────┴─────────┐                                          │
│  │   note_app_ws     │  Laravel Reverb (WebSocket)             │
│  │   host :8080      │                                          │
│  └───────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
         ▲ HTTP :8000                    ▲ WebSocket :8080
         └──────── Browser ──────────────┘
```

| Service | Container name | Image / build | Host port | Internal DNS name |
|---------|------------------|---------------|-----------|-------------------|
| `app` | `note_app_web` | Custom `Dockerfile` (`php:8.2-apache`) | **8000** → 80 | `app` |
| `db` | `note_app_db` | `postgres:15-alpine` | **5433** → 5432 | `db` |
| `redis` | `note_app_redis` | `redis:alpine` | **6379** | `redis` |
| `websocket` | `note_app_ws` | Same image as `app` | **8080** | `websocket` |

**Persistence:** Named volumes `postgres_data` and `redis_data` keep data across `docker compose down` (without `-v`).

**Isolation:** Containers communicate only via Docker DNS (`db`, `redis`, `app`, `websocket`), not via `localhost` inside the app container.

---

## Prerequisites

| Component | Minimum version |
|-----------|-----------------|
| Docker Engine | 24.0+ |
| Docker Compose | V2 (`docker compose`) |
| RAM (free) | ~4 GB recommended |
| Disk | ~5 GB free (images + volumes) |

**Before starting:**

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and ensure the engine is running.
2. Stop XAMPP Apache/MySQL if they use ports **80**, **3306**, or **5432**.
3. Ensure ports **8000**, **5433**, **6379**, and **8080** are free on the host.

---

## Quick Start (Docker — recommended)

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd note-app-final-hoan-thien
```

### 2. Start the full stack

```bash
docker compose up -d --build
```

This command will:

- Build the Laravel/Apache image from `Dockerfile`
- Pull PostgreSQL and Redis images
- Create the `note_network` bridge network
- Start all four services in dependency order (DB and Redis health checks first)
- Run migrations and seed demo users when `RUN_MIGRATIONS=true` (set in `docker-compose.yml`)

First build may take several minutes.

### 3. Verify containers

```bash
docker compose ps
```

Expected output (all **running**; `db` and `redis` should show **healthy**):

| Container | Port mapping | Purpose |
|-----------|--------------|---------|
| `note_app_web` | `0.0.0.0:8000->80/tcp` | Web application |
| `note_app_db` | `0.0.0.0:5433->5432/tcp` | PostgreSQL |
| `note_app_redis` | `0.0.0.0:6379->6379/tcp` | Redis |
| `note_app_ws` | `0.0.0.0:8080->8080/tcp` | WebSocket (Reverb) |

### 4. Seed demo accounts (if not already seeded)

Migrations and seeding usually run automatically on first start. If demo logins fail:

```bash
docker exec note_app_web php artisan migrate --force
docker exec note_app_web php artisan db:seed --force
```

### 5. Open the application

**http://localhost:8000**

- Landing page: `/`
- Login: `/login`

---

## Environment Variables

For Docker, variables are injected in `docker-compose.yml`. For local `.env`, copy from the example:

```bash
cp .env.example .env
```

### Docker / Compose (primary)

| Variable | Value in Compose | Description |
|----------|------------------|-------------|
| `DB_CONNECTION` | `pgsql` | PostgreSQL driver |
| `DB_HOST` | `db` | Database service name (not `127.0.0.1`) |
| `DB_PORT` | `5432` | Internal container port |
| `DB_DATABASE` | `note_db` | Database name |
| `DB_USERNAME` | `admin` | Database user |
| `DB_PASSWORD` | `password123` | Database password |
| `REDIS_HOST` | `redis` | Redis service name |
| `SESSION_DRIVER` | `redis` | Sessions stored in Redis |
| `CACHE_STORE` | `redis` | Cache stored in Redis |
| `QUEUE_CONNECTION` | `redis` | Queue backend |
| `RUN_MIGRATIONS` | `true` | Auto-migrate on container start |

### Email (optional)

Required only for real SMTP activation and password-reset emails:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-gmail-app-password
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="Note App"
```

If mail is not configured, registration and login still work; unactivated accounts see an in-app reminder banner.

### WebSocket (Reverb)

```env
REVERB_APP_ID=123456
REVERB_APP_KEY=noteappkey
REVERB_APP_SECRET=noteappsecret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

When testing from the browser on the host machine, `REVERB_HOST=localhost` and port `8080` match the published `websocket` service port.

---

## Demo Credentials

| Email | Password | Suggested test |
|-------|----------|----------------|
| `demo@example.com` | `123456` | Create notes, share with demo2, lock/pin/labels |
| `demo2@example.com` | `123456` | Open shared notes, edit in real time with demo1 |

> **Grading tip:** Open two browser windows (normal + Incognito), log in as each account, share a note with **Can edit**, then edit the same note in both windows to verify WebSocket collaboration.

---

## Testing Real-time Collaboration

1. Log in as `demo@example.com` → create or open a note → **Share** → enter `demo2@example.com` → permission **Can edit**.
2. Log in as `demo2@example.com` in another window → **Shared with me** → open the note.
3. Type in one window; changes should appear in the other within about one second.

Ensure `note_app_ws` is running:

```bash
docker compose logs -f websocket
```

---

## Useful Docker Commands

```bash
# Stop containers (keep volumes / data)
docker compose down

# Stop and remove volumes (deletes database data)
docker compose down -v

# View logs
docker compose logs -f app
docker compose logs -f db
docker compose logs -f websocket

# Shell inside web container
docker exec -it note_app_web bash

# Run Artisan commands
docker exec note_app_web php artisan migrate:status
docker exec note_app_web php artisan config:clear

# Resource usage
docker stats --no-stream

# Rebuild after Dockerfile or dependency changes
docker compose up -d --build
```

---

## Troubleshooting

| Problem | Likely cause | Fix |
|---------|--------------|-----|
| Port 8000 already in use | Another app on 8000 | Stop the other service or change `"8000:80"` in `docker-compose.yml` |
| `Connection refused` to database | DB not ready yet | Wait for healthy status: `docker compose ps`; restart: `docker compose restart app` |
| Redis connection error | `REDIS_HOST=127.0.0.1` in `.env` | Inside Docker use `REDIS_HOST=redis`; use Compose env overrides |
| Login works but no demo users | Seed not run | `docker exec note_app_web php artisan db:seed --force` |
| Real-time sync not working | WebSocket down | `docker compose ps` → check `note_app_ws`; `docker compose logs websocket` |
| Permission errors on storage | Volume mount permissions | `docker exec note_app_web chown -R www-data:www-data storage bootstrap/cache` |
| Blank page after clone | Missing vendor / key | Rebuild: `docker compose up -d --build` |

**Verify internal DNS from the app container:**

```bash
docker exec -it note_app_web ping -c 2 db
docker exec -it note_app_web ping -c 2 redis
```

---

## Local Setup (XAMPP — optional)

Docker is the **recommended** setup for Topic 10. XAMPP is only for local development without containers.

**Requirements:** XAMPP (Apache + MySQL), PHP ≥ 8.2, Composer.

1. Copy the project to e.g. `C:\xampp\htdocs\note-app-final-hoan-thien\`
2. Create MySQL database `note_laravel_db` in phpMyAdmin.
3. Configure `.env` for MySQL and file sessions:

   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=note_laravel_db
   DB_USERNAME=root
   DB_PASSWORD=

   SESSION_DRIVER=file
   CACHE_STORE=file
   QUEUE_CONNECTION=sync
   ```

4. Install and migrate:

   ```bash
   composer install
   php artisan key:generate
   php artisan migrate --seed
   php artisan storage:link
   ```

5. Start Reverb in a **second** terminal (real-time features):

   ```bash
   php artisan reverb:start --host=0.0.0.0 --port=8080
   ```

6. Open: `http://localhost/note-app-final-hoan-thien/public/` (adjust path to your folder name).

---

## Application Features

### Authentication & profile

- Registration with strong password rules (8+ chars, upper, lower, digit, special)
- Email activation link (SMTP optional)
- Login / logout (sessions on Redis in Docker)
- Forgot password with 6-digit OTP (15-minute expiry)
- Profile: display name, avatar upload with crop/zoom, change password
- User preferences: theme, font size, note colors

### Notes

- CRUD with single editor UI for create and edit
- Auto-save (1 s debounce)
- Grid / list view
- Pin notes to top
- Multiple image attachments
- Live search (300 ms debounce, title + content)
- Delete with confirmation

### Labels

- Create, rename, delete labels
- Assign multiple labels per note
- Filter by label in sidebar

### Security

- Per-note password lock (bcrypt)
- Unlock and remove lock with password confirmation

### Sharing & collaboration

- Share by registered email (read-only or can edit)
- Shared-with-me view
- Revoke or change permissions
- Real-time co-editing via Laravel Reverb (WebSocket)

### UI

- Responsive layout (Bootstrap 5)
- Light / dark mode

---

## Project Structure

```
note-app-final-hoan-thien/
├── app/                    # Laravel application logic
│   ├── Http/Controllers/   # Auth, Note, Label, Profile
│   └── Models/             # User, Note, Label, NoteShare, ...
├── database/
│   ├── migrations/         # PostgreSQL-compatible schema
│   └── seeders/            # Demo users (demo@ / demo2@)
├── docker-compose.yml      # 4-service orchestration
├── Dockerfile              # PHP 8.2 + Apache + pdo_pgsql + redis
├── docker-entrypoint.sh    # Migrations, seed, Apache port config
├── public/                 # Web root (index.php, CSS, JS)
├── resources/views/        # Blade templates
├── routes/web.php          # HTTP routes
└── README.md               # This file
```

**Key configuration files for Topic 10 report:**

| File | Purpose |
|------|---------|
| `Dockerfile` | Image build: PHP extensions, Composer, Apache document root |
| `docker-compose.yml` | Services, networks, volumes, health checks, env |
| `docker-entrypoint.sh` | Startup: migrate, seed, storage link, Apache `PORT` |

---

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Laravel 12 Documentation](https://laravel.com/docs)
- [PostgreSQL 15 Documentation](https://www.postgresql.org/docs/15/)
- [Laravel Reverb](https://laravel.com/docs/reverb)

---

*Midterm project — Topic 10: Containerization & Orchestration. For detailed Docker study notes (Vietnamese), see `HUONG_DAN_DOCKER_CHI_TIET.md`.*
