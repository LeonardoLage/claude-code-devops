# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Kube-News** is a Node.js news portal designed to demonstrate containerization and Kubernetes patterns. It features intentional chaos engineering endpoints for testing Kubernetes liveness/readiness probes.

## Commands

All commands run from the `src/` directory:

```bash
cd src
npm install       # install dependencies
npm start         # start server on port 8080 (runs node server.js)
```

No linting or test suite is configured.

## Architecture

The application is a classic Express + EJS + PostgreSQL monolith:

- **`src/server.js`** — entry point; registers middleware, defines all CRUD routes (`GET/POST /post`, `GET /post/:id`, `GET /`, `POST /api/post`), calls `models.initDatabase()`, and listens on port 8080.
- **`src/system-life.js`** — exports two things: `routers` (an Express router handling `/health`, `/ready`, `/unhealth`, `/unreadyfor/:seconds`) and `middlewares.healthMid` (a middleware that returns HTTP 500 for all requests when the app is in an unhealthy state). The `isHealth` and `readTime` flags are module-level state — they survive across requests but reset on process restart.
- **`src/middleware.js`** — a single `countRequests` middleware that increments a Prometheus counter per method+path.
- **`src/models/post.js`** — Sequelize `Post` model connected to PostgreSQL. Calls `seque.sync({ alter: true })` on startup (auto-migrates schema). All DB config comes from env vars with defaults.

## Environment Variables

| Variable | Default |
|---|---|
| `DB_DATABASE` | `kubedevnews` |
| `DB_USERNAME` | `kubedevnews` |
| `DB_PASSWORD` | `Pg#123` |
| `DB_HOST` | `localhost` |
| `DB_PORT` | `5432` |
| `DB_SSL_REQUIRE` | `false` |

## Key Behaviors

- **Middleware order matters**: `healthMid` is registered before routes, so it intercepts all traffic when unhealthy. Prometheus metrics middleware runs before `healthMid`.
- **`/health` does not respect `isHealth`**: the liveness route always returns `{ state: "up", machine: "<hostname>" }` — the unhealthy state only blocks via the `healthMid` middleware applied to all routes, which means `/health` also returns 500 when unhealthy (since `healthMid` runs first in the chain).
- **`POST /post` validation logic is inverted**: the condition marks `valid = true` when fields are *too short*, not too long. This is an existing bug in the code.
- **Bulk insert**: `POST /api/post` accepts `{ artigos: [{title, resumo, description}] }` and inserts without field validation.
- **Metrics**: available at `/metrics` via `express-prom-bundle`.

## Testing Endpoints Manually

Use `popula-dados.http` (REST Client format) to seed the database with sample posts, or send requests directly:

```bash
curl -X PUT http://localhost:8080/unreadyfor/30   # make unready for 30s
curl -X PUT http://localhost:8080/unhealth         # make unhealthy permanently (until restart)
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/metrics
```
