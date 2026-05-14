# Note Management Application

> **Course**: WEB PROGRAMMING & APPLICATIONS - 503073  
> **Topic 10**: Containerization & Orchestration (Docker)

## Technology Stack

| Layer        | Technology                                |
|-------------|-------------------------------------------|
| Backend     | Laravel 12 (PHP 8.2)                      |
| Frontend    | Bootstrap 5.3 + Bootstrap Icons           |
| Database    | PostgreSQL 15 (Docker container)          |
| Cache       | Redis Alpine (Session & Cache store)      |
| Real-time   | WebSocket (Laravel Reverb)                |
| PWA         | Service Worker + IndexedDB                |
| Container   | Docker + Docker Compose                   |

---

## System Architecture

The application follows a **multi-tier architecture** with 4 isolated Docker services:

```
┌──────────────────────────────────────────────────────────────┐
│                    Docker Network (note_network)             │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌──────────┐  ┌──────────┐ │
│  │  App (Web) │  │  Database  │  │   Cache  │  │WebSocket │ │
│  │ PHP+Apache │  │ PostgreSQL │  │   Redis  │  │  Reverb  │ │
│  │  :8000     │  │  :5432     │  │  :6379   │  │  :8080   │ │
│  └────────────┘  └────────────┘  └──────────┘  └──────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## Quick Start with Docker (Recommended)

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

### Step 1: Clone the repository
```bash
git clone <repository-url>
cd note-app-final-hoan-thien
```

### Step 2: Start all services
```bash
docker-compose up -d --build
```
This single command will:
- Build the PHP/Apache application container
- Start PostgreSQL 15 database with persistent volume
- Start Redis for session/cache management
- Start WebSocket server for real-time collaboration
- Run database migrations automatically

### Step 3: Verify services
```bash
docker ps
```
You should see 4 containers running:
| Container         | Port  | Status |
|-------------------|-------|--------|
| `note_app_web`    | 8000  | Up     |
| `note_app_db`     | 5433  | Up     |
| `note_app_redis`  | 6379  | Up     |
| `note_app_ws`     | 8080  | Up     |

### Step 4: Seed demo accounts (first time only)
```bash
docker exec note_app_web php artisan db:seed --force
```

### Step 5: Access the application
Open your browser and navigate to: **http://localhost:8000**

---

## Local Setup (XAMPP Alternative)

### Prerequisites
- XAMPP (Apache + MySQL)
- PHP >= 8.2

### Steps
1. Copy the project to `C:\xampp\htdocs\note-laravel\`
2. Create a database named `note_laravel_db` in phpMyAdmin
3. Update `.env`:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=note_laravel_db
   DB_USERNAME=root
   DB_PASSWORD=
   ```
4. Install dependencies and run migrations:
   ```bash
   C:\xampp\php\php.exe composer.phar install
   C:\xampp\php\php.exe artisan migrate --seed
   C:\xampp\php\php.exe artisan storage:link
   ```
5. Access: `http://localhost/note-laravel/public/`

---

## Environment Variables

Copy `.env.example` to `.env` and configure:

```env
# Database (Docker defaults)
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=note_db
DB_USERNAME=admin
DB_PASSWORD=password123

# Cache & Session (Redis)
SESSION_DRIVER=redis
CACHE_STORE=redis
REDIS_HOST=redis

# Email (optional - for activation & password reset)
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

---

## Demo Credentials

| Email               | Password |
|---------------------|----------|
| demo@example.com    | 123456   |
| demo2@example.com   | 123456   |

> Use both accounts to test **Note Sharing & Real-time Collaboration** features.

---

## Running WebSocket Server (Real-time Collaboration)

The WebSocket server starts automatically in Docker via the `websocket` service.

For local development (XAMPP):
```bash
C:\xampp\php\php.exe server\websocket.php
```
WebSocket runs on port **8081**. Keep this terminal open for collaboration features.

---

## Email Configuration (Optional)

In `.env`:
```env
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-16-char-app-password
```
> If email is not configured, accounts still work (an activation banner is displayed).

---

## Key Features

### Authentication & User Management
- ✅ Registration with strong password validation (uppercase, lowercase, digit, special char)
- ✅ Email activation with token-based verification
- ✅ Login / Logout with session management
- ✅ Forgot password with 6-digit OTP (15-min expiry)
- ✅ Profile management (name, avatar with crop & zoom)
- ✅ Change password

### Note Management (CRUD)
- ✅ Create / Read / Update / Delete notes
- ✅ Auto-save with 1-second debounce (no Save button needed)
- ✅ Grid / List view toggle
- ✅ Attach multiple images to notes
- ✅ Pin notes to top
- ✅ Live Search with 300ms debounce

### Labels & Organization
- ✅ Full CRUD for labels
- ✅ Assign labels to notes
- ✅ Filter notes by label (sidebar)

### Security
- ✅ Lock notes with password (bcrypt hashed)
- ✅ Unlock with password verification
- ✅ Remove lock with current password confirmation

### Sharing & Collaboration
- ✅ Share notes via email (Read-only / Edit permissions)
- ✅ View notes shared with you
- ✅ Update / Revoke share permissions
- ✅ Real-time collaboration via WebSocket

### Customization
- ✅ Font size preference (small / medium / large)
- ✅ Note background color picker
- ✅ Dark / Light theme toggle

### Technical
- ✅ Responsive Design (Bootstrap 5)
- ✅ PWA with Service Worker & IndexedDB offline support
- ✅ Docker containerization with 4-service architecture
- ✅ PostgreSQL + Redis + WebSocket services
- ✅ Container isolation with dedicated Docker network
