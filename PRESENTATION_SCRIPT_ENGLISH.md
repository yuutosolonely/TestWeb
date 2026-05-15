# 🎤 LIVE DEMO PRESENTATION SCRIPT
## Note Management Web Application — Topic 10: Containerization & Orchestration
### Web Programming & Applications (503073) — Midterm

---

> ## 📋 HOW TO USE THIS SCRIPT
>
> - This script is **demo-first**. You speak while doing things — in the terminal, in the code editor, in the browser.
> - **`[TYPE]`** = type this exact command in the terminal right now.
> - **`[OPEN]`** = open this file or URL on screen.
> - **`[SHOW]`** = point to / scroll to something already on screen.
> - **`[WAIT]`** = pause and let the output complete before continuing.
> - *(Italic text)* = private stage directions, do NOT read aloud.
> - You do **not** need slides. Your screen IS the presentation.
>
> **Time targets:**
> - **Part A — Docker Core Demo:** ~10 minutes
> - **Part B — Feature Demo (your features):** ~5–10 minutes

---
---

# ═══ PART A: DOCKER CORE DEMO (~10 MINUTES) ═══

---

## 🟢 OPENING — Set the Scene
### ⏱️ ~30 seconds | *[Have the terminal open in the project folder]*

Good morning / afternoon, everyone.

What you're looking at right now is my terminal, open inside our project folder — the **Note Management Web Application**. This is our midterm project for Topic 10 — **Containerization and Orchestration with Docker**.

Instead of walking you through slides, I'm going to **show you exactly how the system works** — from the raw configuration files, to launching it live, to testing every major feature in the browser.

Let's start.

---

## 🔵 STEP 1 — Walk Through the Project Files
### ⏱️ ~1.5 minutes | *[Open the project folder in VS Code or the terminal]*

`[OPEN]` — Open the project root folder. Show the file list.

```
note-app-final-hoan-thien/
├── Dockerfile
├── docker-compose.yml
├── docker-entrypoint.sh
├── app/
├── database/
├── resources/
└── ...
```

> "These are the three files that make Topic 10 work. Everything else is the Laravel application itself.
> Let me open each one and explain what it does."

---

### 1.1 — Open `Dockerfile`

`[OPEN]` — `Dockerfile`

> "The Dockerfile is the **recipe** for building our web application's container image.
> Think of it like a script that Docker follows step by step to package our app."

`[SHOW]` — Line 1:
```dockerfile
FROM php:8.2-apache
```
> "We start from the official PHP 8.2 + Apache image from Docker Hub. That's our base — a web server already configured."

`[SHOW]` — The `RUN apt-get install` block:
```dockerfile
RUN ... docker-php-ext-install pdo_pgsql pgsql gd zip \
    && pecl install redis \
    && docker-php-ext-enable redis
```
> "Then we install the PHP extensions our app needs:
> - `pdo_pgsql` — so Laravel can talk to PostgreSQL.
> - `gd` — for image processing, used in our avatar crop feature.
> - `redis` — for our cache and session layer.
> These are installed *inside the container image*, so they're always there — no manual setup."

`[SHOW]` — Composer line:
```dockerfile
RUN composer install --no-dev --optimize-autoloader
```
> "Composer, PHP's package manager, installs all Laravel dependencies inside the image. The `--optimize-autoloader` flag speeds up class loading in production."

`[SHOW]` — Apache document root line:
```dockerfile
RUN sed -i 's|/var/www/html|/var/www/html/public|g' ...
```
> "And finally, we point Apache's document root to Laravel's `public/` folder — so the web server only exposes the public entry point, not our source code."

`[SHOW]` — Last two lines:
```dockerfile
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
```
> "When the container starts, it first runs our custom entrypoint script, then starts Apache."

---

### 1.2 — Open `docker-compose.yml`

`[OPEN]` — `docker-compose.yml`

> "This is the **orchestration file** — it defines all four services that make up our system and how they connect."

`[SHOW]` — The 4 service blocks:

> "We have exactly four services — four independent containers:

> **Service 1 — `app`**: This is our Laravel web application. It builds from the Dockerfile we just saw, and it publishes on port `8000`."

`[SHOW]` — `app` service's `depends_on` block:
```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_healthy
```
> "This is important — the app container will NOT start until both the database AND Redis pass their health checks. This prevents startup crashes from race conditions."

> "**Service 2 — `db`**: PostgreSQL 15. Our database. It runs the official `postgres:15-alpine` image — no custom build needed."

`[SHOW]` — `db` service's `healthcheck`:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U admin -d note_db"]
  interval: 5s
  retries: 5
```
> "Every 5 seconds, Docker probes `pg_isready` inside the container. Only when that passes does the app container start."

`[SHOW]` — `volumes` section at the bottom:
```yaml
volumes:
  postgres_data:
  redis_data:
```
> "These named volumes store database and Redis data *outside* the containers. Even if I run `docker compose down`, the data is still here. I'd need `docker compose down -v` to actually wipe it."

> "**Service 3 — `redis`**: Our cache and session store. Instead of reading sessions from disk, we read them from RAM. Instant response."

> "**Service 4 — `websocket`**: This runs Laravel Reverb — our WebSocket server. This is what enables multiple users to co-edit a note in real time."

`[SHOW]` — `networks` section:
```yaml
networks:
  note_network:
    driver: bridge
```
> "All four containers are on this private bridge network. They find each other by service name — for example, the app connects to the database using the hostname `db`, not `localhost`. External traffic can't reach the database directly — only the app can."

---

### 1.3 — Open `docker-entrypoint.sh`

`[OPEN]` — `docker-entrypoint.sh`

> "This script runs automatically every time the app container starts. It's our automation layer — so a fresh `docker compose up` just works, without any manual steps."

`[SHOW]` — The port configuration block:
```bash
APP_PORT="${PORT:-80}"
sed -ri "s/^Listen [0-9]+/Listen ${APP_PORT}/" /etc/apache2/ports.conf
```
> "First, it configures Apache's port. This is especially important for Railway — our cloud deployment — where the port is dynamically assigned by the platform via the `PORT` environment variable."

`[SHOW]` — Migration block:
```bash
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    for i in $(seq 1 30); do
        if php artisan migrate:status > /dev/null 2>&1; then
            DB_READY=true; break
        fi
        sleep 1
    done
    php artisan migrate --force
    php artisan db:seed --force
fi
```
> "Then it checks whether `RUN_MIGRATIONS=true` is set. If yes, it *waits* for the database — retrying up to 30 times — and only then runs migrations and seeds the demo data. This is robust startup automation."

`[SHOW]` — Cache clear lines:
```bash
php artisan config:clear
php artisan route:clear
```
> "Finally, it clears the config cache so environment variables from `docker-compose.yml` take effect immediately."

---

## 🔵 STEP 2 — Launch the System Live
### ⏱️ ~2 minutes

`[TYPE]` — In terminal, at the project root:
```bash
docker compose up -d --build
```

> "This single command is the entire deployment process. Docker will:
> - Build our Laravel image from the Dockerfile
> - Pull the PostgreSQL and Redis images from Docker Hub
> - Create the private `note_network`
> - Start all four services in the correct dependency order
>
> The first build takes a few minutes because it downloads images and installs dependencies. On subsequent runs, it's much faster because Docker caches the layers."

`[WAIT]` — *(while building, keep talking)*

> "Notice Docker is processing each layer of the Dockerfile sequentially — installing system packages, then PHP extensions, then Composer dependencies. Each step is cached, so if only our application code changes on the next build, Docker skips straight to the copy step."

`[WAIT until build completes]`

---

## 🔵 STEP 3 — Verify Containers are Running
### ⏱️ ~1 minute

`[TYPE]`:
```bash
docker compose ps
```

`[SHOW]` — Output:

> "All four containers are up:
> - `note_app_web` — our app, on port 8000
> - `note_app_db` — PostgreSQL, on port 5433
> - `note_app_redis` — Redis, on port 6379
> - `note_app_ws` — WebSocket server, on port 8080
>
> Notice `note_app_db` and `note_app_redis` show status **healthy** — that's the health check passing. The app container waited for these before starting."

`[TYPE]`:
```bash
docker compose logs app --tail=30
```

`[SHOW]` — Scroll through logs:

> "In the logs we can see the entrypoint script ran — it waited for the database, ran the migrations, seeded the demo data, and then started Apache. This is a fully automated, zero-manual-step deployment."

---

## 🔵 STEP 4 — Explore Running Containers
### ⏱️ ~1 minute

`[TYPE]`:
```bash
docker exec -it note_app_web bash
```

> "I can open a shell directly inside the running container. This is like SSH-ing into a server."

`[TYPE inside container]`:
```bash
php artisan migrate:status
```

> "We can see all migration files have been applied — all our tables exist in PostgreSQL inside the container."

`[TYPE inside container]`:
```bash
php artisan tinker --execute="echo 'App running on PHP ' . PHP_VERSION;"
```

> "PHP 8.2 confirmed. Now let me exit."

`[TYPE]`:
```bash
exit
```

`[TYPE]`:
```bash
docker stats --no-stream
```

> "We can also inspect resource usage. Each container runs in isolation — their CPU, memory, and network are all independent. This is container isolation in practice."

---

## 🔵 STEP 5 — Open the Application in Browser
### ⏱️ ~30 seconds

`[OPEN]` — Browser, navigate to: **`http://localhost:8000`**

> "And here it is — the live application. No XAMPP, no manual PHP setup, no database configuration. Just one command."

> "I'll log in with our demo account."

`[TYPE in browser]` — Email: `demo@example.com`, Password: `123456` → Login.

> "We're in. This is the main dashboard."

---
---

# ═══ PART B: FEATURE DEMO (~5–10 MINUTES) ═══
### *(Your personal features — account verification excluded)*

> **📌 FOR PRESENTER:** Demo each feature hands-on in the browser. Speak while you interact — don't just describe, show. Account verification is excluded as requested.

---

## 🟡 DEMO 1 — Auto-save (Debounce)
### ⏱️ ~1.5 minutes

> "The first feature I implemented is **Auto-save**. There is no Save button in this application."

`[ACTION]` — Click on an existing note to open it, or create a new one.

> "Watch the top right corner as I type something."

`[ACTION]` — Type some text in the note title or body. Type slowly and stop.

> "You can see a small indicator appears — 'Saving...' — and then it becomes 'Saved ✓'. This happens automatically after I stop typing for **1 second**."

> "Under the hood, this is a JavaScript **debounce** technique. Every keystroke resets a 1-second timer. Only after that timer fires does the browser send a `fetch()` AJAX request to the Laravel API, which updates the record in PostgreSQL — through the Redis session for authentication."

`[ACTION]` — Navigate away from the note and come back to it.

> "The changes are there. No Save button. No page reload. This is the same experience as Google Keep or Notion."

---

## 🟡 DEMO 2 — Note Locking
### ⏱️ ~1.5 minutes

> "Next — **Note Password Protection**. I can lock any note so its content is hidden until the correct password is entered."

`[ACTION]` — Find a note → click the lock icon or the three-dot menu → select "Lock Note."

> "I'll set a password for this note."

`[ACTION]` — Type a password and confirm it.

> "Now watch when I go back to the dashboard."

`[ACTION]` — Navigate back to the notes list.

> "The note is now shown as locked — its content is completely hidden, even in the preview. Let me click on it."

`[ACTION]` — Click the locked note.

> "A password prompt appears. I need the correct password to read this note."

`[ACTION]` — Enter the correct password.

> "Now I can read it. The important security detail here: the password is NOT stored in plain text. It is hashed with **Bcrypt** — the same algorithm used for user account passwords. Even direct database access cannot reveal it."

> "And there's a 'Remove Lock' option — but to use it, you must first prove you know the current password. You can't simply clear the lock."

---

## 🟡 DEMO 3 — Label System & Filtering
### ⏱️ ~1.5 minutes

> "Now let me show the **Label System** — our way to classify and filter notes."

`[ACTION]` — In the sidebar, click "Manage Labels" or the Labels section.

> "I can create labels like 'Work', 'Study', or 'Personal'. Let me create one."

`[ACTION]` — Create a new label, e.g., "Study".

> "Now let me go to a note and assign this label."

`[ACTION]` — Open a note → find the Label/Tag section → assign "Study" to it.

> "Now back to the dashboard — I click 'Study' in the sidebar."

`[ACTION]` — Click the "Study" label in the sidebar.

> "The note list instantly filters to show only notes tagged with 'Study'. This is a direct Eloquent ORM query — no page reload, just fast filtered results."

> "I can combine this with the live search bar — filter by label AND type a keyword simultaneously."

`[ACTION]` — With the label filter active, type a keyword in the search bar.

> "The results narrow down even further in real time, using a 300ms debounce."

---

## 🟡 DEMO 4 — Grid / List View & Note Pinning
### ⏱️ ~1 minute

> "Two quick UI features: **View Mode Toggle** and **Note Pinning**."

`[ACTION]` — Click the Grid/List toggle button in the top toolbar.

> "Switching between Grid view — cards in a Pinterest-style layout — and List view — compact rows, better for many notes. The preference is saved in `localStorage` and persists between sessions."

`[ACTION]` — Find an important note → click the Pin icon.

> "Pinned notes jump to the top of the list, above everything else — in both Grid and List view. When I unpin it, it returns to its original position."

---

## 🟡 DEMO 5 — Dark Mode, Note Color Picker, Font Size
### ⏱️ ~1 minute

> "Three UI customization features bundled together."

`[ACTION]` — Click the Dark Mode toggle (sun/moon icon).

> "Dark mode — the entire interface switches instantly. The preference is stored in `localStorage` — no flash of the wrong theme on reload."

`[ACTION]` — Open a note → find the Color Picker option.

> "Each note can have its own background color — inspired by Google Keep. The color is saved in the database and displayed on the card and inside the editor."

`[ACTION]` — Choose a color, observe it on the card.

`[ACTION]` — Go to Settings or the font size control.

> "Finally, font size — Small, Medium, or Large. Also persisted in `localStorage` so your reading preference is always remembered."

---

## 🟡 BONUS DEMO — Real-time Collaboration (WebSocket)
### ⏱️ ~1.5 minutes | *[Only if time allows or if the professor asks]*

> "Let me quickly show the WebSocket collaboration — this is one of the most impressive features."

`[ACTION]` — Open a second browser window in **Incognito mode**.

> "In this window I'll log in as our second demo account."

`[TYPE in incognito]` — Login as `demo2@example.com` / `123456`.

> "In the first window — logged in as `demo@example.com` — I'll share a note with demo2."

`[ACTION in window 1]` — Open a note → Share → enter `demo2@example.com` → permission: **Can edit** → Share.

`[ACTION in window 2 - demo2]` — Go to "Shared with me" → open the shared note.

> "Now both users have this note open at the same time. Watch what happens when I type in one window."

`[ACTION in window 1]` — Type some text in the note.

> "The changes appear in **demo2's window instantly** — no refresh, no polling. This is the Reverb WebSocket container doing its job — broadcasting events between connected clients in real time."

`[TYPE in terminal]`:
```bash
docker compose logs websocket --tail=10
```

> "In the WebSocket container logs, we can see the broadcast event being fired for every keystroke — this is the live event stream that powers real-time collaboration."

---
---

## 🔴 CLOSING — 30 Seconds

> "To wrap up:
>
> We launched a complete, production-grade web system — four containers, three services beyond the app itself — using a **single command**. The Dockerfile built the image, the `docker-compose.yml` orchestrated the services, and the entrypoint script automated the setup.
>
> Every feature works out of the box — from auto-save, to note locking, to real-time collaboration — all because the environment is consistent and containerized.
>
> That's Topic 10 in action.
>
> Thank you. I'm happy to answer any questions."

---
---

## 📎 APPENDIX — Key Commands Reference (for Q&A)

```bash
# Start everything
docker compose up -d --build

# Check all containers
docker compose ps

# See live logs
docker compose logs -f app
docker compose logs -f websocket

# Open shell inside web container
docker exec -it note_app_web bash

# Run Artisan commands without entering container
docker exec note_app_web php artisan migrate:status
docker exec note_app_web php artisan db:seed --force
docker exec note_app_web php artisan config:clear

# Check resource usage per container
docker stats --no-stream

# Verify inter-container DNS works
docker exec -it note_app_web ping -c 2 db
docker exec -it note_app_web ping -c 2 redis

# Stop without losing data
docker compose down

# Stop AND delete all volumes (wipes database)
docker compose down -v

# Rebuild after code changes
docker compose up -d --build
```

---

## 📎 APPENDIX — Anticipated Q&A

**Q: Why not just use XAMPP?**
> A: XAMPP is great for local development but it only works on your specific machine with your specific configuration. Docker packages the exact PHP version, PostgreSQL, Redis — everything — into containers that run identically everywhere. That's why it matters for deployment and teamwork.

**Q: Why PostgreSQL instead of MySQL?**
> A: Topic 10 specifically requires PostgreSQL. Beyond the requirement, PostgreSQL is preferred in microservices architectures for its stronger ACID compliance and JSONB support. Laravel's Eloquent ORM handles both databases almost identically, so migration was simple.

**Q: What does `service_healthy` mean in docker-compose?**
> A: It means the app container waits not just for the database *process* to start, but for it to actually pass a readiness probe — `pg_isready`. PostgreSQL takes a few seconds to initialize after the process starts. Without this, the app would try to connect before the database is ready and crash.

**Q: What if I delete a container — do I lose the data?**
> A: No. Containers and data are separate. Named volumes (`postgres_data`, `redis_data`) are managed by Docker independently. `docker compose down` stops and removes containers but keeps the volumes. You need `docker compose down -v` to also wipe the data.

**Q: How does auto-save work without blocking the user?**
> A: JavaScript's debounce technique — every keystroke resets a 1-second timer. Only after the user stops typing for 1 second does it fire a `fetch()` call to the API. The user keeps typing freely while the save happens in the background on the previous debounced event.

**Q: How does real-time collaboration work technically?**
> A: When a user saves a note, Laravel fires a `NoteUpdated` broadcast event. Laravel Reverb — our WebSocket server running in its own container — receives this event and pushes it to all clients subscribed to that note's private channel. The browser's JavaScript listener receives it and updates the displayed content without any refresh.

---

*End of Script*
