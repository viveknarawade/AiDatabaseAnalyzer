# AI Database Analyst — System Architecture & Database Schema

---

## 1. HIGH-LEVEL ARCHITECTURE

### Architecture Style: **Modular Monolith** (with async workers)

A modular monolith is the right starting point for a SaaS MVP. It avoids microservice overhead while keeping clear module boundaries that can be split later.

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND (React + Vite)               │
│  Dashboard │ Schema Explorer │ Query Editor │ Insights   │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTPS (JWT)
                       ▼
┌─────────────────────────────────────────────────────────┐
│              BACKEND (Spring Boot)                       │
│                                                         │
│  ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌───────────┐ │
│  │ Auth     │ │ Project  │ │ Analysis  │ │ Query     │ │
│  │ Module   │ │ Module   │ │ Module    │ │ Module    │ │
│  └──────────┘ └──────────┘ └───────────┘ └───────────┘ │
│  ┌──────────┐ ┌──────────┐ ┌───────────┐               │
│  │ Schema   │ │ DataQual │ │ Insight   │               │
│  │ Module   │ │ Module   │ │ Module    │               │
│  └──────────┘ └──────────┘ └───────────┘               │
│                       │                                 │
│            ┌──────────┴──────────┐                      │
│            ▼                     ▼                      │
│     ┌────────────┐      ┌──────────────┐               │
│     │ Redis Cache│      │ Task Queue   │               │
│     │            │      │ (Redis/Bull) │               │
│     └────────────┘      └──────┬───────┘               │
└─────────────────────────────────┼───────────────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ PostgreSQL   │   │ AI/LLM       │   │ User's       │
    │ (App DB)     │   │ (OpenAI API) │   │ Target DBs   │
    └──────────────┘   └──────────────┘   └──────────────┘
```

### Data Flow

1. **User connects a database** → Frontend sends connection details → Backend encrypts & stores credentials → Background job introspects schema (tables, columns, relationships, indexes)
2. **Schema analysis** → Worker reads `information_schema` from target DB → Stores metadata in app DB → Generates ER diagram data
3. **AI summaries** → Worker sends schema context to OpenAI → Receives business-level descriptions → Stores in `ai_summaries`
4. **Data quality** → Worker runs profiling queries (nulls, duplicates, type mismatches) → Stores metrics
5. **NL-to-SQL** → User types natural language → Backend sends schema context + question to LLM → Returns generated SQL → User can execute against target DB
6. **Insights** → Periodic or on-demand job analyzes patterns across metrics → Generates actionable insights

---

## 2. DATABASE SCHEMA

### Table: `users`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, DEFAULT gen_random_uuid() |
| email | VARCHAR(255) | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL |
| full_name | VARCHAR(100) | NOT NULL |
| avatar_url | TEXT | NULLABLE |
| email_verified | BOOLEAN | DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `user_roles`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id) ON DELETE CASCADE |
| role | app_role ENUM | ('admin', 'member', 'viewer') NOT NULL |
| | | UNIQUE(user_id, role) |

---

### Table: `projects`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id) ON DELETE CASCADE |
| name | VARCHAR(100) | NOT NULL |
| description | TEXT | NULLABLE |
| status | VARCHAR(20) | DEFAULT 'active' |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `data_sources`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| project_id | UUID | FK → projects(id) ON DELETE CASCADE |
| name | VARCHAR(100) | NOT NULL |
| db_type | VARCHAR(20) | NOT NULL (postgres, mysql, mssql, etc.) |
| host | VARCHAR(255) | NOT NULL |
| port | INTEGER | NOT NULL |
| database_name | VARCHAR(100) | NOT NULL |
| username_encrypted | TEXT | NOT NULL |
| password_encrypted | TEXT | NOT NULL |
| ssl_enabled | BOOLEAN | DEFAULT true |
| connection_status | VARCHAR(20) | DEFAULT 'pending' |
| last_synced_at | TIMESTAMPTZ | NULLABLE |
| created_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `schema_tables`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| data_source_id | UUID | FK → data_sources(id) ON DELETE CASCADE |
| schema_name | VARCHAR(100) | DEFAULT 'public' |
| table_name | VARCHAR(255) | NOT NULL |
| table_type | VARCHAR(20) | 'TABLE' or 'VIEW' |
| estimated_row_count | BIGINT | NULLABLE |
| size_bytes | BIGINT | NULLABLE |
| description | TEXT | NULLABLE (from DB comments) |
| synced_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `schema_columns`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| table_id | UUID | FK → schema_tables(id) ON DELETE CASCADE |
| column_name | VARCHAR(255) | NOT NULL |
| data_type | VARCHAR(100) | NOT NULL |
| is_nullable | BOOLEAN | DEFAULT true |
| is_primary_key | BOOLEAN | DEFAULT false |
| is_unique | BOOLEAN | DEFAULT false |
| default_value | TEXT | NULLABLE |
| max_length | INTEGER | NULLABLE |
| ordinal_position | INTEGER | NOT NULL |
| description | TEXT | NULLABLE |

---

### Table: `schema_relationships`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| data_source_id | UUID | FK → data_sources(id) ON DELETE CASCADE |
| source_table_id | UUID | FK → schema_tables(id) |
| source_column_id | UUID | FK → schema_columns(id) |
| target_table_id | UUID | FK → schema_tables(id) |
| target_column_id | UUID | FK → schema_columns(id) |
| relationship_type | VARCHAR(10) | '1:1', '1:N', 'N:M' |
| constraint_name | VARCHAR(255) | NULLABLE |

---

### Table: `data_quality_metrics`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| table_id | UUID | FK → schema_tables(id) ON DELETE CASCADE |
| column_id | UUID | FK → schema_columns(id), NULLABLE |
| metric_type | VARCHAR(50) | NOT NULL (completeness, uniqueness, etc.) |
| metric_value | NUMERIC(10,4) | NOT NULL |
| sample_size | BIGINT | NULLABLE |
| details | JSONB | NULLABLE |
| measured_at | TIMESTAMPTZ | DEFAULT now() |

**metric_type values:** completeness, uniqueness, validity, consistency, null_percentage, duplicate_count, min_value, max_value, avg_length, pattern_match

---

### Table: `ai_summaries`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| data_source_id | UUID | FK → data_sources(id) ON DELETE CASCADE |
| target_type | VARCHAR(20) | 'data_source', 'table', 'column' |
| target_id | UUID | NOT NULL (polymorphic ref) |
| summary_text | TEXT | NOT NULL |
| llm_model | VARCHAR(50) | NOT NULL |
| prompt_tokens | INTEGER | NULLABLE |
| completion_tokens | INTEGER | NULLABLE |
| generated_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `nl_queries`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users(id) |
| data_source_id | UUID | FK → data_sources(id) |
| natural_language | TEXT | NOT NULL |
| generated_sql | TEXT | NOT NULL |
| is_valid | BOOLEAN | NULLABLE |
| execution_time_ms | INTEGER | NULLABLE |
| result_row_count | INTEGER | NULLABLE |
| user_feedback | VARCHAR(10) | NULLABLE ('good', 'bad') |
| llm_model | VARCHAR(50) | NOT NULL |
| created_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `insights`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| data_source_id | UUID | FK → data_sources(id) ON DELETE CASCADE |
| category | VARCHAR(30) | NOT NULL (performance, anomaly, recommendation, pattern) |
| severity | VARCHAR(10) | 'info', 'warning', 'critical' |
| title | VARCHAR(255) | NOT NULL |
| description | TEXT | NOT NULL |
| affected_tables | UUID[] | Array of schema_table IDs |
| suggested_action | TEXT | NULLABLE |
| is_dismissed | BOOLEAN | DEFAULT false |
| generated_at | TIMESTAMPTZ | DEFAULT now() |

---

### Table: `job_queue`

| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| project_id | UUID | FK → projects(id) |
| job_type | VARCHAR(30) | NOT NULL (schema_sync, quality_check, ai_summary, insight_gen) |
| status | VARCHAR(20) | 'pending', 'running', 'completed', 'failed' |
| payload | JSONB | NULLABLE |
| result | JSONB | NULLABLE |
| error_message | TEXT | NULLABLE |
| started_at | TIMESTAMPTZ | NULLABLE |
| completed_at | TIMESTAMPTZ | NULLABLE |
| created_at | TIMESTAMPTZ | DEFAULT now() |

---

## 3. ER DIAGRAM (Relationships)

```
users 1──N projects
users 1──N user_roles
users 1──N nl_queries

projects 1──N data_sources

data_sources 1──N schema_tables
data_sources 1──N schema_relationships
data_sources 1──N ai_summaries
data_sources 1──N nl_queries
data_sources 1──N insights

schema_tables 1──N schema_columns
schema_tables 1──N data_quality_metrics
schema_tables 1──N schema_relationships (as source)
schema_tables 1──N schema_relationships (as target)

schema_columns 1──N data_quality_metrics
schema_columns 1──N schema_relationships (as source_column)
schema_columns 1──N schema_relationships (as target_column)

projects 1──N job_queue
```

---

## 4. SCALABILITY DESIGN

### Handling Large Databases

| Challenge | Solution |
|-----------|----------|
| Schema with 500+ tables | Paginated introspection; sync in batches of 50 tables |
| Data quality on millions of rows | Sample-based profiling (10K–100K rows) with `TABLESAMPLE` |
| AI context window limits | Chunk schema into groups of related tables; summarize per-group |
| Concurrent users | Connection pooling (HikariCP); read replicas for analytics |

### Async Processing

All heavy operations run as background jobs:

1. **Schema sync** — Triggered on data source creation or manual refresh. Worker connects to target DB, reads `information_schema`, writes to app DB.
2. **Data quality checks** — Scheduled or on-demand. Runs profiling queries against target DB using read-only connection.
3. **AI summary generation** — Queued after schema sync completes. Processes tables in batches to stay within token limits.
4. **Insight generation** — Runs after quality metrics are updated. Analyzes patterns across metrics.

**Implementation:** Spring Boot `@Async` with `ThreadPoolTaskExecutor` for simple jobs. Redis-backed queue (Spring Data Redis) for distributed/retriable jobs.

### Caching Strategy (Redis)

| What | TTL | Invalidation |
|------|-----|-------------|
| Schema metadata | 1 hour | On schema sync |
| Data quality metrics | 30 min | On quality check |
| AI summaries | 24 hours | On regeneration |
| User sessions/JWT | Token expiry | On logout |
| NL-to-SQL results | 1 hour | Per data source |

---

## 5. SECURITY

### Authentication

- **JWT-based** with access token (15 min) + refresh token (7 days)
- Passwords hashed with bcrypt (cost factor 12)
- Email verification required before accessing features
- Rate limiting on auth endpoints (5 attempts/min)

### Role-Based Access

| Role | Permissions |
|------|------------|
| admin | Full access, manage users, billing |
| member | Create projects, connect DBs, run queries |
| viewer | Read-only access to shared projects |

Roles stored in `user_roles` table (never on user profile). Checked via `has_role()` security-definer function.

### Secure Database Connections

- Credentials encrypted at rest using AES-256 (encryption key in env var, not in DB)
- Target DB connections use SSL by default
- Read-only connections enforced (app creates read-only DB user recommendation)
- Connection credentials never returned to frontend
- Target DB queries have statement timeout (30s) to prevent long-running queries

---

## 6. TECH STACK SUMMARY

| Layer | Technology |
|-------|-----------|
| Frontend | React 18 + Vite + TypeScript + Tailwind CSS |
| Backend | Spring Boot 3 + Java 17 |
| App Database | PostgreSQL 15 |
| Cache | Redis 7 |
| AI/LLM | OpenAI GPT-4o API |
| Auth | Spring Security + JWT |
| Task Queue | Redis-backed (Spring) |
| DB Connectivity | JDBC (multi-driver: PG, MySQL, MSSQL, Oracle) |
| Deployment | Docker Compose → Kubernetes when scaling |

---

## 7. API ENDPOINTS (Key Routes)

```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh

GET    /api/projects
POST   /api/projects
GET    /api/projects/:id

POST   /api/projects/:id/data-sources        (connect DB)
POST   /api/data-sources/:id/sync            (trigger schema sync)
GET    /api/data-sources/:id/tables
GET    /api/data-sources/:id/er-diagram

GET    /api/tables/:id/columns
GET    /api/tables/:id/quality-metrics
POST   /api/tables/:id/run-quality-check

GET    /api/data-sources/:id/summaries
POST   /api/data-sources/:id/generate-summary

POST   /api/data-sources/:id/nl-query        (natural language → SQL)
POST   /api/data-sources/:id/execute-query    (run generated SQL)

GET    /api/data-sources/:id/insights
GET    /api/data-sources/:id/data-dictionary

GET    /api/jobs/:id                          (check job status)
```

---

*This architecture is designed to be practical, implementable as an MVP, and scalable as the product grows.*
