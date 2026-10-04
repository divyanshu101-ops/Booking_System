# Booking System: Setup Notes (Phase 1)

These notes cover **only the environment setup** done so far: folders, Node project, Docker, Docker Compose, PostgreSQL, Redis, the app container and the health check. No business logic exists yet.

**Stack:** Node.js 20, Express 5, PostgreSQL 16, Redis 7, Docker + Docker Compose (C++ stress tester comes later).

---

## 1. Folder structure

```
9_Booking_System/
├── docker-compose.yml      → defines and wires all containers
├── .env                    → credentials and connection strings
├── .gitignore              → keeps .env and node_modules out of Git
├── db/                     → SQL schema (init.sql comes in the next phase)
├── stress-test/            → C++ multithreaded tester (last phase)
└── app/
    ├── Dockerfile          → recipe to build the app image
    ├── .dockerignore       → files Docker must not copy into the image
    ├── package.json
    └── src/
        ├── server.js       → entry point
        ├── config/         → DB and Redis connections (db.js, redis.js)
        ├── routes/         → maps URL to controller, nothing else
        ├── controllers/    → reads request, validates, calls service, sends response
        ├── services/       → real business logic, transactions, locks
        └── middleware/     → rate limiter, idempotency (reused across routes)
```

### Why this layering (routes → controllers → services)

| Layer | Job | Knows about HTTP? |
|---|---|---|
| Route | `POST /bookings` → `bookingController.create` | Yes |
| Controller | Validate input, call the service, turn the result into a status code (201, 400, 409) | Yes |
| Service | "This user wants these seats": transaction, `FOR UPDATE`, wallet movement | **No** |

- The service never sees `req` or `res`, so the booking logic is independent of HTTP and easy to test.
- Errors are thrown by the service ("seat already booked") and translated by the controller (409 Conflict).
- Middleware is separate because rate limiting and idempotency are reused by many routes.
- `db/` and `stress-test/` live outside `app/` because they are not part of the Node application.

---

## 2. Node project (`app/`)

### Packages installed

| Package | Why |
|---|---|
| `express` | HTTP server and routing. Version 5 forwards errors from async handlers automatically, so no try/catch wrapper is needed. |
| `pg` | PostgreSQL driver. Gives a connection pool and full control over `BEGIN`, `COMMIT`, `ROLLBACK` and `SELECT ... FOR UPDATE`. **No ORM on purpose**: this project is about locking, and we need exact control over the SQL. |
| `ioredis` | Redis client for seat locks, rate limiting and idempotency keys. |

### `package.json` choices

- `"type": "module"` → the whole project uses `import / export`, never `require`.
- `"main": "src/server.js"` → the real entry file.
- Scripts:
  - `dev`: `node --watch src/server.js` restarts the server on every file save. `--watch` is built into Node, so nodemon is not needed.
  - `start`: `node src/server.js` without watch (production style).

### ES module rules to remember

- Local imports **must include the extension**: `import pool from './config/db.js'`.
- `pg` is a CommonJS package, so it is imported as:
  ```js
  import pg from 'pg';
  const { Pool } = pg;
  ```

---

## 3. Why Docker

Docker packages the app and its dependencies into an **image**, and runs it as an isolated **container**.

- **Same environment everywhere.** No "works on my machine" problem. PostgreSQL 16 and Redis 7 are the same versions on any computer.
- **No manual installs.** PostgreSQL and Redis are not installed on Windows. They are just containers that can be created and destroyed in seconds.
- **Easy reset.** A broken database can be wiped and rebuilt with one command.
- **Reproducible for interviews.** Anyone can clone the repo and run the whole system with a single command.

## 4. Why Docker Compose

A single `docker run` starts one container. This project needs **three** (app, PostgreSQL, Redis) that must talk to each other. Compose lets us describe all of them in one file, `docker-compose.yml`, and manage them together.

- **One command** (`docker compose up`) starts everything.
- **Automatic private network.** Containers can reach each other by **service name** (`postgres`, `redis`).
- **Startup ordering** with `depends_on` plus health checks.
- **Declarative config.** Ports, volumes and environment variables are written down in a file, not remembered or typed by hand.

---

## 5. Environment variables (`.env`)

```
POSTGRES_USER=booking
POSTGRES_PASSWORD=booking
POSTGRES_DB=booking
DATABASE_URL=postgres://booking:booking@postgres:5432/booking
REDIS_URL=redis://redis:6379
```

- Loaded into containers through `env_file: .env` in Compose, so credentials are **not hardcoded** in `docker-compose.yml` or in the code.
- The `POSTGRES_*` variables make the PostgreSQL image create the user and the `booking` database **automatically on first start**. Nothing needs to be created manually in pgAdmin.
- `.env` must be listed in `.gitignore` so credentials never reach GitHub. (These values are dummy, but it is the correct habit.) A `.env.example` without real values can be committed instead.
- Check with `git ls-files .env`: it should print nothing.

### Hostnames inside vs outside Docker

| Who is connecting | Host | Port |
|---|---|---|
| App container → PostgreSQL | `postgres` | `5432` |
| App container → Redis | `redis` | `6379` |
| Windows tools (pgAdmin, C++ tester) → PostgreSQL | `localhost` | `5433` |
| Windows tools → Redis | `localhost` | `6380` |
| Windows → App | `localhost` | `3000` |

Inside Compose's private network, containers use **service names and the container ports**. The `5433` and `6380` ports exist only for tools running on Windows.

---

## 6. PostgreSQL container

```yaml
postgres:
  image: postgres:16-alpine
  env_file: .env
  ports:
    - "5433:5432"
  volumes:
    - pgdata:/var/lib/postgresql/data
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U booking -d booking"]
    interval: 3s
    retries: 10
```

| Line | Reason |
|---|---|
| `postgres:16-alpine` | PostgreSQL 16 on Alpine Linux, a much smaller image. |
| `"5433:5432"` | Format is `host:container`. PostgreSQL listens on 5432 inside; Windows reaches it on 5433. A different host port avoids a clash with any local PostgreSQL. |
| `pgdata` volume | Stores the data **outside** the container. Without it, deleting the container deletes the database. |
| `healthcheck` | `pg_isready` runs every 3 seconds. Container is marked **healthy** only when PostgreSQL really accepts connections. |

**Note on `db/init.sql`:** scripts in `/docker-entrypoint-initdb.d/` run **only the first time**, when the volume is empty. After a schema change, run `docker compose down -v` to wipe the volume and re-initialise.

**Rule:** never create tables manually in pgAdmin. All schema goes into `init.sql`, so the whole database can be rebuilt from scratch with one command.

---

## 7. Redis container

```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6380:6379"
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 3s
    retries: 10
```

- `6380:6379` follows the same logic as PostgreSQL (avoid clashing with a local Redis).
- Health check: `redis-cli ping` must answer `PONG`.
- **No volume, on purpose.** Redis will only hold *temporary coordination data*: seat locks with TTL, rate-limit counters, idempotency keys. The source of truth is PostgreSQL. If Redis restarts, locks simply expire and nothing durable is lost.
- Interview line: *"Redis is for fast, temporary coordination. Durable state lives in PostgreSQL."*

---

## 8. App container

### `app/Dockerfile`

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY src ./src
CMD ["npm", "run", "dev"]
```

| Line | Reason |
|---|---|
| `FROM node:20-alpine` | Small Node 20 base image. |
| `WORKDIR /app` | All following commands run inside `/app`. |
| `COPY package*.json ./` then `RUN npm install` | Dependencies are installed **before** the source is copied. |
| `COPY src ./src` | Source code is copied last. |
| `CMD ["npm","run","dev"]` | Starts the app with `node --watch`. |

**Layer caching:** Docker caches every instruction as a layer. Because `package.json` changes rarely and source code changes constantly, putting `npm install` before `COPY src` means a code change only rebuilds the last layer. Dependencies are **not** reinstalled, so rebuilds are fast.

### `app/.dockerignore`

```
node_modules
```

The Windows `node_modules` must not be copied into the image. The container runs its own `npm install` for Linux, because some packages are OS-specific.

### App service in Compose

```yaml
app:
  build: ./app
  env_file: .env
  ports:
    - "3000:3000"
  volumes:
    - ./app/src:/app/src
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

| Line | Reason |
|---|---|
| `build: ./app` | Build the image from `app/Dockerfile`. |
| `ports: "3000:3000"` | Windows `localhost:3000` reaches the Express server. |
| `volumes: ./app/src:/app/src` | **Bind mount**: the Windows `src` folder is shared with the container. Saving a file triggers `node --watch` to restart the server, with no image rebuild. |
| `depends_on` + `service_healthy` | App starts only after PostgreSQL and Redis are *actually ready*, not merely started. This prevents "database wasn't ready, app crashed" failures. |

Because of the bind mount, the `COPY src ./src` in the Dockerfile is only a fallback. The mounted folder replaces it at runtime.

---

## 9. Connection code

### `config/db.js`

```js
import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
});

export default pool;
```

- **Why a pool:** opening a new connection per request is slow. The pool keeps connections open and reuses them.
- **Why `max: 20` on purpose:** later, 100+ concurrent stress-test requests will compete for 20 connections, and the waiting becomes part of the lock-wait and throughput analysis.

### `config/redis.js`

```js
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

export default redis;
```

One shared Redis connection for the whole app.

### `server.js` and the health endpoint

```js
import express from 'express';
import pool from './config/db.js';
import redis from './config/redis.js';

const app = express();
app.use(express.json());

app.get('/health', async (req, res) => {
  await pool.query('SELECT 1');
  await redis.ping();
  res.json({ status: 'ok' });
});

app.listen(3000, () => console.log('app up on 3000'));
```

`/health` runs a trivial query on **both** PostgreSQL and Redis. If it returns `{"status":"ok"}`, the app, the database and the cache are all connected end to end.

---

## 10. Verification and daily commands

| Command | Purpose |
|---|---|
| `docker compose up -d --build` | Build and start everything in the background. |
| `docker compose ps` | All three containers should be `Up`; PostgreSQL and Redis `healthy`. |
| `docker compose logs app` | Should show `app up on 3000`. |
| `curl.exe localhost:3000/health` | Should return `{"status":"ok"}`. |
| `docker compose exec redis redis-cli ping` | Should return `PONG`. |
| `docker compose exec postgres psql -U booking -d booking` | Open a SQL shell inside PostgreSQL. |
| `docker compose restart app` | Restart only the app (useful if Windows file watching misses a save). |
| `docker compose down` | Stop and remove containers. **Data is kept** in the `pgdata` volume. |
| `docker compose down -v` | Same, and also **deletes the data**. Needed to re-run `init.sql`. |

Results observed: all containers healthy, `PONG` from Redis, `app up on 3000` in logs, and `{"status":"ok"}` from `/health`.

---

## 11. Mistakes made and lessons

- **YAML indentation.** `redis:` was accidentally nested under `postgres:`, giving the error `services.postgres additional properties 'redis' not allowed`. Fix: `postgres:`, `redis:` and `app:` must all sit at the same level (2 spaces) under `services:`. Never use Tabs in YAML.
- **`localhost` vs service names.** Inside a container, `localhost` means *that container itself*. Use `postgres` and `redis` in `.env` connection strings.
- **Committing `.env`.** Always confirm it is ignored by Git.

---

## 12. Architecture of the current setup

### Container diagram

```mermaid
flowchart LR
  subgraph H["Windows host"]
    C["curl / browser / future C++ stress tester"]
    PA["pgAdmin (optional)"]
  end

  subgraph D["Docker Compose private network"]
    A["app container<br/>Node 20 + Express 5<br/>:3000"]
    PG[("postgres container<br/>PostgreSQL 16<br/>:5432")]
    R[("redis container<br/>Redis 7<br/>:6379")]
  end

  V[("pgdata volume")]
  S["./app/src on Windows<br/>(bind mount)"]

  C -->|"localhost:3000"| A
  PA -->|"localhost:5433"| PG
  A -->|"postgres:5432<br/>DATABASE_URL"| PG
  A -->|"redis:6379<br/>REDIS_URL"| R
  PG --- V
  S -.->|"live code reload"| A
```

### Same thing in plain text

```
                        WINDOWS HOST
   ┌──────────────────────────────────────────────────────┐
   │  curl / browser / (later) C++ stress tester          │
   │  pgAdmin (optional)                                  │
   │       │ localhost:3000                │ localhost:5433│
   └───────┼───────────────────────────────┼──────────────┘
           │                               │
   ┌───────┼───────────────────────────────┼──────────────┐
   │       ▼        DOCKER COMPOSE NETWORK ▼              │
   │  ┌──────────┐   postgres:5432   ┌──────────────┐     │
   │  │   app    │ ────────────────▶ │  postgres 16 │──┐  │
   │  │ Node 20  │                   └──────────────┘  │  │
   │  │ Express 5│   redis:6379      ┌──────────────┐  ▼  │
   │  │  :3000   │ ────────────────▶ │   redis 7    │ pgdata
   │  └────▲─────┘                   └──────────────┘ volume
   │       │ bind mount: ./app/src ⇄ /app/src             │
   └───────┼──────────────────────────────────────────────┘
           │
     source code on Windows (edit → auto restart)
```

### Startup order

```
docker compose up
   │
   ├─▶ postgres starts ──▶ pg_isready passes ──▶ HEALTHY ─┐
   │                                                      ├─▶ app starts
   └─▶ redis starts ─────▶ redis-cli ping passes ▶ HEALTHY ┘     │
                                                                  ▼
                                                  GET /health → SELECT 1 + PING
                                                  → {"status":"ok"}
```

### Responsibilities

| Component | Role in the final system |
|---|---|
| **app** (Node + Express) | REST API and all booking logic. |
| **postgres** | Source of truth: shows, seats, bookings, wallets. Transactions and `FOR UPDATE` locking. |
| **redis** | Temporary seat locks (TTL), sliding-window rate limiting, idempotency keys. |
| **pgdata volume** | Keeps database data when containers are removed. |
| **bind mount** | Edit code on Windows, see changes instantly in the container. |
