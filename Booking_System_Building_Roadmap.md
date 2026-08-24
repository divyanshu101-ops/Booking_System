# Project Plan — AI-Integrated Booking System

> Goal: Extend the primary Movie/Event Ticket Booking System with an AI Customer Support Assistant (RAG-based), for a Backend Engineer + AI Integration resume profile.
> Stack: Node.js + Express + PostgreSQL + Redis + LLM API
> Approach: Understand → Design → Write code yourself → Run locally → Test → Break/test edge cases → Debug → Understand failure → Improve → Scale/Secure/Monitor

---

## Why This Project

This replaces the earlier plan of building the Real-Time Sync Engine and Self-Healing Distributed Cache as separate resume projects within 1 month — those were assessed as too ambitious to complete well alongside learning backend fundamentals in parallel. This plan instead builds on the already-in-progress primary learning project (Booking System), adding a genuine AI integration layer (RAG — Retrieval-Augmented Generation) on top of a properly engineered backend.

**Frontend scope:** Minimal, bare-bones only (seat map, booking form, AI chat box) — 1-2 days max, no design polish. Primary time budget stays on backend + AI integration.

---

# Week 1 — Routing → Layered Architecture → REST Design (Foundation)

| Day | Topic                         | What Gets Built                                                                                                                                                   |
| --- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Routing                       | Full route map for Booking System (`/shows`, `/seats`, `/bookings`, `/users`) — route params, query params, nested routes, route-level middleware basics |
| 2   | Serialization/Deserialization | JSON parsing/formatting, transforming DB rows → clean API responses, hiding internal fields (e.g. password hash never leaves the server)                         |
| 3   | Auth Part 1 — Authentication | User signup/login, password hashing (bcrypt), issuing JWTs                                                                                                        |
| 4   | Auth Part 2 — Authorization  | Role-based access (customer vs admin/venue-owner), protecting routes with middleware                                                                              |
| 5   | Validation & Transformations  | Input validation (e.g. zod/joi) for booking requests — reject bad seatId, missing fields, invalid types before they touch business logic                         |
| 6   | Layered Architecture          | Refactor into Controllers → Services → Repositories → Middleware; understand why each layer exists (separation of concerns, testability)                       |
| 7   | REST API Design               | Proper resource naming, status codes, pagination for`/shows`, versioning strategy (`/api/v1/...`), consistent error response shape                            |

**Week 1 deliverable:** A properly layered, authenticated, validated REST API — the foundation the AI layer will sit on top of.

---

# Week 2 — Database, Caching, Reliability

| Day | Topic                                  | What Gets Built                                                                                                                              |
| --- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 8   | Postgres Part 1 — Schema Design       | Full schema:`users`, `venues`, `shows`, `seats`, `show_seats`, `bookings`, `payments` — proper foreign keys, constraints      |
| 9   | Postgres Part 2 — Transactions        | Wrap booking creation in a DB transaction; understand ACID; what happens if a step fails halfway                                             |
| 10  | Postgres Part 3 — Concurrency/Locking | Core lesson of this project: two users booking the same seat —`SELECT ... FOR UPDATE`, row-level locking, prevent double-booking for real |
| 11  | Caching                                | Cache show listings / seat availability reads with Redis; decide what must NEVER be cached (live seat status) vs what can be (show details)  |
| 12  | Error Handling                         | Centralized error-handling middleware, custom error classes, consistent error responses across the whole API                                 |
| 13  | Configuration Management               | Move secrets/config (DB URL, JWT secret, future AI API key) into`.env`, environment-based config (dev/prod)                                |
| 14  | Buffer + Review Day                    | Catch up on anything that ran long; re-test the full booking flow end-to-end (seat hold → book → cancel → conflict case)                  |

**Week 2 deliverable:** A production-shaped booking backend — handles concurrency correctly, cached where it should be, errors handled cleanly, secrets externalized. Resume-worthy even without the AI layer.

---

# Week 3 — AI Customer Support Assistant (RAG Layer)

| Day | Topic                          | What Gets Built                                                                                                                                                                     |
| --- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 15  | LLM API basics                 | Get API access, understand the chat/messages request shape, send a first "hello world" call from the backend                                                                        |
| 16  | Prompt design + system prompt  | Design the assistant's system prompt: "You are a booking support assistant. Only answer using the provided context. Never invent booking details."                                  |
| 17  | Context retrieval — Part 1    | Given a user's question, decide what data to fetch from Postgres (their bookings, relevant policy text) — the "R" in RAG                                                           |
| 18  | Context retrieval — Part 2    | Build the retrieval function: e.g.`getRelevantContext(userId, question)` → returns booking history + matched policy snippets                                                     |
| 19  | Build`/support/ask` endpoint | Wire it together: user question → retrieve context → inject into prompt → call LLM → return answer. Test with real questions ("what's my booking status", "can I get a refund") |
| 20  | Guardrails & failure handling  | What if the LLM API is down? Rate limits? User asks something unrelated/malicious (prompt injection attempt)? Add fallbacks, timeouts, input sanitization                           |
| 21  | Testing + refinement           | Test edge cases: no bookings yet, cancelled booking, ambiguous questions. Refine prompt based on bad answers observed                                                               |

**Week 3 deliverable:** A working AI support endpoint that answers real questions using real booking data — the core resume differentiator.

---

# Week 4 — Security, Observability, Minimal Frontend, Polish

| Day | Topic                                  | What Gets Built                                                                                                                                                            |
| --- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 22  | Backend Security                       | Rate limiting (especially on`/support/ask` — LLM calls cost money and can be abused), input sanitization, SQL injection prevention check, CORS config, helmet.js basics |
| 23  | Logging/Monitoring (lightweight)       | Structured logging (request logs, error logs, AI call logs with latency), a simple way to see what's happening (well-formatted console/file logs)                          |
| 24  | Scaling & Concurrency (concept-level)  | Review: where would this break under load? Document the answers even without fully implementing horizontal scaling — shows engineering maturity in the README             |
| 25  | Minimal Frontend — Day 1              | Bare-bones HTML/React: seat map view + booking form, wired to the real API                                                                                                 |
| 26  | Minimal Frontend — Day 2              | AI chat box UI, wired to`/support/ask`. Stop here — no more frontend time after today                                                                                   |
| 27  | Documentation + README                 | Architecture diagram, setup instructions, "engineering decisions" section (what broke, what was learned, trade-offs made)                                                  |
| 28  | Demo recording + final polish + buffer | Record a short demo video (seat booking + AI assistant answering a real question), final GitHub push, buffer for anything overrunning                                      |

**Week 4 deliverable:** A secure, documented, demo-able, GitHub-ready project.

---

# Honest Engineering Notes

- **Task Queues and full horizontal scaling are not deeply implemented in this plan** — not enough time to do them justice alongside everything else in one month. Day 24 is about *thinking through and documenting* these instead of building them fully. This is a legitimate, honest thing to state in a README ("here's how I'd scale this further") — often more impressive to interviewers than a half-working queue system.
- **Week 3 (AI) depends on Weeks 1-2 being solid.** If Postgres/Auth/booking logic slips, the AI layer has nothing real to retrieve context from. Protect Weeks 1-2 more than Week 4's polish if something has to give.
- **Days 14 and 28 are deliberate buffers** — distributed/concurrency bugs and AI prompt tuning both eat unpredictable time. Don't skip them by cramming ahead.

---

# Quick Reference — Weekly Themes

| Week | Theme                | Core Question Being Answered                                 |
| ---- | -------------------- | ------------------------------------------------------------ |
| 1    | Foundation           | Is the API well-structured, authenticated, and validated?    |
| 2    | Reliability          | Does it handle concurrency, caching, and errors correctly?   |
| 3    | Differentiation      | Can it intelligently answer questions using real data (RAG)? |
| 4    | Production-readiness | Is it secure, observable, demo-able, and documented?         |
