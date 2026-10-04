# Concurrent Movie Ticket Booking System

> 🚧 **Work in progress.** This repo is being built step by step in public. The environment is ready; the booking logic is under construction. See the [roadmap](#roadmap) for what is done and what is next.

A backend for booking movie seats where **many users fight for the same seat at the same time**, and the system must give each seat to exactly one of them and never lose or create money.

The project is about concurrency and correctness: row-level locking, transactions, temporary seat holds, idempotency and load testing.

## How it works

There are two roles:

- **Admin** (one seeded account): creates and deletes shows, sets the price of every seat, and sees total earnings.
- **User**: registers with a fixed starting wallet balance, holds seats, pays from the wallet, and can cancel for a refund.

Booking is a two-step flow, like real ticketing apps:

```mermaid
flowchart LR
  A["Browse shows<br/>and seat map"] --> B["Hold seats<br/>(Redis, expires in minutes)"]
  B --> C["Confirm and pay<br/>(PostgreSQL transaction)"]
  C --> D["Seats booked<br/>wallet debited<br/>ledger updated"]
  B -. "timer runs out" .-> E["Seats free again"]
```

1. **Hold:** selected seats are locked temporarily in Redis with a TTL. If the user does nothing, they free themselves.
2. **Confirm:** one PostgreSQL transaction locks the seats (`SELECT ... FOR UPDATE`), checks they are still free, charges the user's wallet, records the booking and the money movement, and marks the seats booked. Either everything happens or nothing does.

PostgreSQL is always the source of truth. Redis is only a fast, temporary layer on top.

## Planned features

- Show and seat catalog with live seat status (available / held / booked)
- JWT authentication with separate admin and user permissions
- Wallet payments with an insert-only **ledger** (no hot admin balance row), all amounts stored as integers
- Pessimistic row locking and database constraints against double booking
- Deadlock-safe multi-seat bookings (consistent lock ordering)
- Redis seat holds with TTL auto-expiry
- Sliding-window rate limiting
- Idempotency keys so a double click or retry never charges twice
- Transactional cancellation with refunds
- A multithreaded C++ stress tester with a consistency checker

## Tech stack

Node.js 20, Express 5, PostgreSQL 16, Redis 7, Docker Compose, and C++ for the stress tester.

## Run it locally

Requires Docker.

1. Create a `.env` file in the project root:

   ```
   POSTGRES_USER=booking
   POSTGRES_PASSWORD=booking
   POSTGRES_DB=booking
   DATABASE_URL=postgres://booking:booking@postgres:5432/booking
   REDIS_URL=redis://redis:6379
   ```

2. Start everything:

   ```
   docker compose up -d --build
   ```

3. Check that the app, PostgreSQL and Redis are connected:

   ```
   curl localhost:3000/health
   ```

   Expected: `{"status":"ok"}`

Stop with `docker compose down` (add `-v` to also delete the database data).

## Project structure

```
├── docker-compose.yml     app, postgres and redis containers
├── db/                    SQL schema
├── stress-test/           C++ load tester
└── app/
    └── src/
        ├── config/        database and Redis connections
        ├── routes/        URL mapping
        ├── controllers/   request and response handling
        ├── services/      booking logic, transactions, locks
        └── middleware/    auth, rate limit, idempotency
```

## Roadmap

- [x] Docker Compose environment (app, PostgreSQL, Redis) with health checks
- [x] Express app connected to both, `/health` endpoint
- [ ] Database schema with constraints
- [ ] Authentication (register, login, JWT, admin and user roles)
- [ ] Admin show management and seat catalog
- [ ] Core booking with transactions and row locking
- [ ] Cancellation and refunds
- [ ] Redis seat holds with TTL
- [ ] Idempotency keys and rate limiting
- [ ] C++ stress tester and consistency checks
- [ ] Simple frontend
- [ ] Final write-up of design decisions and test results

Performance numbers will be added here only after they are measured by the project's own stress test.
