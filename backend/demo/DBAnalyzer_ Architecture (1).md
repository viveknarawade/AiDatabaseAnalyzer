# AI Database Analyst — Production Architecture & Database Design

---

## 1. Architecture Overview

### Architecture Style: Modular Monolith (Microservices-Ready)

The system starts as a **modular monolith** deployed as a single Spring Boot application with clearly separated internal modules. Each module has its own service layer, repository layer, and API controllers, communicating through in-process method calls — not HTTP.

**Modules:**

| Module | Responsibility |
|---|---|
| `auth` | JWT authentication, RBAC, token management |
| `project` | Project + member CRUD, access control |
| `connector` | External DB connection management, credential encryption |
| `schema` | Schema extraction, snapshot versioning |
| `quality` | Data quality analysis, metric computation |
| `nlquery` | Natural language → SQL translation via LLM |
| `insight` | AI-powered insight generation |
| `summary` | AI business summary generation |
| `dictionary` | Data dictionary management (AI + manual) |
| `jobs` | Async job orchestration, retry logic |
| `audit` | Audit logging, usage tracking |

**When to split into microservices:**
- When the AI processing module needs independent GPU-backed scaling
- When job workers need 10x more instances than API servers
- When team grows beyond 8 engineers and module ownership becomes necessary
- When a single module's deployment cycle diverges significantly

---

## 2. Component Architecture

### Frontend (React + Vite)
- SPA served from CDN
- Communicates exclusively via REST API
- JWT stored in httpOnly cookies (not localStorage)
- React Query for server state, Context for auth state

### Backend (Spring Boot 3.x, Java 21)
- Stateless — no server-side sessions
- All state in MySQL + Redis
- HikariCP connection pooling (pool size: 10-20 per instance)
- Structured logging with correlation IDs

### Redis (Cache + Queue)
- **Cache**: Schema metadata, AI responses, query results
- **Queue**: Job dispatch using Redis Streams (lightweight alternative to Kafka)
- Separate Redis databases (db0=cache, db1=queue)

### MySQL 8.x (Primary Database)
- Primary for writes, read replica for heavy reads (schema browsing, reports)
- InnoDB engine, utf8mb4 charset
- Partitioning on `audit_logs` and `usage_tracking` by month

### OpenAI API
- GPT-4o for SQL generation and insights
- GPT-4o-mini for data dictionary descriptions (cost optimization)
- Retry with exponential backoff, circuit breaker pattern

---

## 3. Request & Data Flow

### Synchronous API Request (e.g., NL → SQL)

```
Client → CDN → Load Balancer → API Gateway
  → JWT Validation → Rate Limit Check
  → Spring Boot Controller
    → Check Redis cache (schema + query hash)
    → If miss: Load schema from MySQL
    → Build prompt with schema context
    → Call OpenAI API
    → Parse response, validate SQL
    → Cache result in Redis (TTL: 15min)
    → Log to usage_tracking
    → Return response to client
```

### Async Job Flow (e.g., Schema Extraction)

```
Client → POST /data-sources/{id}/sync → 202 Accepted
  → Create job_queue record (status: PENDING)
  → Publish to Redis Stream "jobs:schema"
  → Worker picks up job
    → Connect to external DB via JDBC
    → Execute INFORMATION_SCHEMA queries
    → Store schema_tables, schema_columns, schema_relationships
    → Increment snapshot_version
    → Invalidate Redis schema cache
    → Update job status → COMPLETED
    → Optionally chain: Enqueue data_quality + dictionary jobs
  → Client polls GET /jobs/{id}/status
```

### AI Processing Flow

```
Worker dequeues AI job
  → Load schema metadata (from cache or DB)
  → If schema > 100 tables: chunk into groups of 25
  → For each chunk:
    → Build prompt with table definitions + relationships
    → Call OpenAI with temperature=0.1 (deterministic)
    → Parse structured JSON response
    → Accumulate results
  → Merge chunk results
  → Store in insights / ai_summaries table
  → Record token usage in usage_tracking
  → Update job status → COMPLETED
```

---

## 4. Database Schema (MySQL 8.x)

### Table: `users`
| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | |
| email | VARCHAR(100) | UNIQUE, NOT NULL | |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt |
| full_name | VARCHAR(100) | NOT NULL | |
| avatar_url | VARCHAR(255) | NULLABLE | |
| status | ENUM('active','suspended','deleted') | DEFAULT 'active' | |
| email_verified_at | TIMESTAMP | NULLABLE | |
| last_login_at | TIMESTAMP | NULLABLE | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | |

**Indexes:** `idx_users_email` (email), `idx_users_status` (status)

---

### Table: `roles`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| name | VARCHAR(50) | UNIQUE, NOT NULL |
| description | VARCHAR(255) | NULLABLE |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Seed data:** admin, member, viewer

---

### Table: `user_roles`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| user_id | BIGINT | FK → users.id ON DELETE CASCADE |
| role_id | BIGINT | FK → roles.id |
| assigned_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `uq_user_role` UNIQUE(user_id, role_id)

---

### Table: `refresh_tokens`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| user_id | BIGINT | FK → users.id ON DELETE CASCADE |
| token_hash | VARCHAR(512) | UNIQUE, NOT NULL |
| expires_at | TIMESTAMP | NOT NULL |
| revoked | BOOLEAN | DEFAULT FALSE |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_refresh_user` (user_id), `idx_refresh_expires` (expires_at)

---

### Table: `projects`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| owner_id | BIGINT | FK → users.id |
| name | VARCHAR(150) | NOT NULL |
| description | TEXT | NULLABLE |
| status | ENUM('active','archived','deleted') | DEFAULT 'active' |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |

**Indexes:** `idx_projects_owner` (owner_id), `idx_projects_status` (status)

---

### Table: `project_members`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| project_id | BIGINT | FK → projects.id ON DELETE CASCADE |
| user_id | BIGINT | FK → users.id ON DELETE CASCADE |
| role | ENUM('admin','editor','viewer') | DEFAULT 'viewer' |
| joined_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `uq_project_member` UNIQUE(project_id, user_id)

---

### Table: `data_sources`
| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | |
| project_id | BIGINT | FK → projects.id ON DELETE CASCADE | |
| name | VARCHAR(100) | NOT NULL | |
| db_type | ENUM('mysql','postgresql','sqlserver','oracle') | NOT NULL | |
| host | VARCHAR(255) | NOT NULL | |
| port | INT | NOT NULL | |
| database_name | VARCHAR(100) | NOT NULL | |
| encrypted_credentials | BLOB | NOT NULL | AES-256 encrypted |
| ssl_enabled | BOOLEAN | DEFAULT TRUE | |
| connection_status | ENUM('connected','disconnected','error') | DEFAULT 'disconnected' | |
| last_synced_at | TIMESTAMP | NULLABLE | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | |

**Indexes:** `idx_ds_project` (project_id), `idx_ds_status` (connection_status)

---

### Table: `schema_tables`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| data_source_id | BIGINT | FK → data_sources.id ON DELETE CASCADE |
| table_name | VARCHAR(150) | NOT NULL |
| table_schema | VARCHAR(100) | DEFAULT 'public' |
| table_type | ENUM('BASE TABLE','VIEW','SYSTEM VIEW') | |
| estimated_row_count | BIGINT | DEFAULT 0 |
| table_comment | VARCHAR(255) | NULLABLE |
| snapshot_version | INT | DEFAULT 1 |
| extracted_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_st_datasource` (data_source_id), `uq_table_name` UNIQUE(data_source_id, table_schema, table_name, snapshot_version)

---

### Table: `schema_columns`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| schema_table_id | BIGINT | FK → schema_tables.id ON DELETE CASCADE |
| column_name | VARCHAR(150) | NOT NULL |
| data_type | VARCHAR(100) | NOT NULL |
| column_type_full | VARCHAR(100) | e.g. VARCHAR(255) |
| is_nullable | BOOLEAN | DEFAULT TRUE |
| column_default | TEXT | NULLABLE |
| column_key | VARCHAR(50) | PRI/UNI/MUL/empty |
| column_comment | VARCHAR(255) | NULLABLE |
| ordinal_position | INT | NOT NULL |
| char_max_length | BIGINT | NULLABLE |
| numeric_precision | INT | NULLABLE |
| numeric_scale | INT | NULLABLE |

**Indexes:** `idx_sc_table` (schema_table_id), `idx_sc_name` (column_name)

---

### Table: `schema_relationships`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| data_source_id | BIGINT | FK → data_sources.id ON DELETE CASCADE |
| source_table_id | BIGINT | FK → schema_tables.id |
| source_column_id | BIGINT | FK → schema_columns.id |
| target_table_id | BIGINT | FK → schema_tables.id |
| target_column_id | BIGINT | FK → schema_columns.id |
| constraint_name | VARCHAR(150) | |
| relationship_type | ENUM('one-to-one','one-to-many','many-to-many') | |

**Indexes:** `idx_sr_datasource` (data_source_id), `idx_sr_source` (source_table_id), `idx_sr_target` (target_table_id)

---

### Table: `data_quality_reports`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| data_source_id | BIGINT | FK → data_sources.id ON DELETE CASCADE |
| triggered_by | BIGINT | FK → users.id |
| status | ENUM('pending','running','completed','failed') | DEFAULT 'pending' |
| summary_metrics | JSON | overall scores |
| started_at | TIMESTAMP | NULLABLE |
| completed_at | TIMESTAMP | NULLABLE |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_dqr_datasource` (data_source_id), `idx_dqr_status` (status)

---

### Table: `data_quality_metrics`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| report_id | BIGINT | FK → data_quality_reports.id ON DELETE CASCADE |
| schema_table_id | BIGINT | FK → schema_tables.id |
| schema_column_id | BIGINT | FK → schema_columns.id, NULLABLE |
| completeness_pct | DECIMAL(5,2) | |
| uniqueness_pct | DECIMAL(5,2) | |
| validity_pct | DECIMAL(5,2) | |
| null_count | BIGINT | DEFAULT 0 |
| distinct_count | BIGINT | DEFAULT 0 |
| total_count | BIGINT | DEFAULT 0 |
| anomalies | JSON | NULLABLE |

**Indexes:** `idx_dqm_report` (report_id), `idx_dqm_table` (schema_table_id)

---

### Table: `ai_summaries`
| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT | |
| project_id | BIGINT | FK → projects.id ON DELETE CASCADE | |
| data_source_id | BIGINT | FK → data_sources.id, NULLABLE | NULL = project-level |
| requested_by | BIGINT | FK → users.id | |
| summary_type | ENUM('executive','technical','data_profile','custom') | NOT NULL | |
| prompt_used | TEXT | NOT NULL | for reproducibility |
| response_content | TEXT | NOT NULL | |
| tokens_input | INT | NOT NULL | |
| tokens_output | INT | NOT NULL | |
| model_used | VARCHAR(50) | NOT NULL | e.g. gpt-4o |
| latency_ms | INT | | |
| status | ENUM('pending','completed','failed') | DEFAULT 'pending' | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

**Indexes:** `idx_ais_project` (project_id), `idx_ais_type` (summary_type), `idx_ais_created` (created_at)

---

### Table: `nl_queries`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| project_id | BIGINT | FK → projects.id ON DELETE CASCADE |
| data_source_id | BIGINT | FK → data_sources.id |
| user_id | BIGINT | FK → users.id |
| natural_language_input | TEXT | NOT NULL |
| generated_sql | TEXT | NULLABLE |
| query_result_preview | JSON | first 50 rows |
| result_row_count | INT | NULLABLE |
| execution_time_ms | INT | NULLABLE |
| tokens_used | INT | DEFAULT 0 |
| user_approved | BOOLEAN | NULLABLE |
| user_feedback | TEXT | NULLABLE |
| status | ENUM('pending','completed','failed','rejected') | DEFAULT 'pending' |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_nlq_project` (project_id), `idx_nlq_user` (user_id), `idx_nlq_created` (created_at)

---

### Table: `insights`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| project_id | BIGINT | FK → projects.id ON DELETE CASCADE |
| data_source_id | BIGINT | FK → data_sources.id |
| generated_by_job | BIGINT | FK → job_queue.id, NULLABLE |
| title | VARCHAR(200) | NOT NULL |
| summary | TEXT | NOT NULL |
| severity | ENUM('info','positive','warning','critical') | NOT NULL |
| category | VARCHAR(100) | |
| supporting_data | JSON | NULLABLE |
| tokens_used | INT | DEFAULT 0 |
| status | ENUM('active','dismissed','archived') | DEFAULT 'active' |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_ins_project` (project_id), `idx_ins_severity` (severity), `idx_ins_created` (created_at)

---

### Table: `data_dictionary_entries`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| schema_column_id | BIGINT | FK → schema_columns.id ON DELETE CASCADE, UNIQUE |
| updated_by | BIGINT | FK → users.id, NULLABLE |
| ai_description | TEXT | NULLABLE |
| user_description | TEXT | NULLABLE |
| tags | JSON | e.g. ["PK","indexed"] |
| sample_values | JSON | NULLABLE |
| business_rules | JSON | NULLABLE |
| last_ai_update | TIMESTAMP | NULLABLE |
| last_user_update | TIMESTAMP | NULLABLE |

**Indexes:** `uq_dict_column` UNIQUE(schema_column_id)

---

### Table: `job_queue`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| job_type | VARCHAR(50) | NOT NULL |
| project_id | BIGINT | FK → projects.id |
| data_source_id | BIGINT | FK → data_sources.id, NULLABLE |
| created_by | BIGINT | FK → users.id |
| payload | JSON | job-specific parameters |
| status | ENUM('pending','running','completed','failed','cancelled') | DEFAULT 'pending' |
| priority | INT | DEFAULT 5 (1=highest) |
| attempt_count | INT | DEFAULT 0 |
| max_attempts | INT | DEFAULT 3 |
| error_message | TEXT | NULLABLE |
| worker_id | VARCHAR(100) | NULLABLE |
| scheduled_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| started_at | TIMESTAMP | NULLABLE |
| completed_at | TIMESTAMP | NULLABLE |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_jq_status_priority` (status, priority), `idx_jq_type` (job_type), `idx_jq_project` (project_id), `idx_jq_scheduled` (scheduled_at)

**Job Types:** `SCHEMA_EXTRACT`, `DATA_QUALITY`, `AI_SUMMARY`, `INSIGHT_GEN`, `DICTIONARY_GEN`, `NL_QUERY_EXEC`

---

### Table: `audit_logs`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| user_id | BIGINT | FK → users.id ON DELETE SET NULL, NULLABLE |
| action | VARCHAR(50) | NOT NULL |
| resource_type | VARCHAR(100) | NOT NULL |
| resource_id | BIGINT | NULLABLE |
| old_values | JSON | NULLABLE |
| new_values | JSON | NULLABLE |
| ip_address | VARCHAR(45) | |
| user_agent | VARCHAR(512) | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_al_user` (user_id), `idx_al_action` (action), `idx_al_created` (created_at)
**Partitioning:** RANGE by YEAR(created_at) — monthly partitions

---

### Table: `usage_tracking`
| Column | Type | Constraints |
|---|---|---|
| id | BIGINT | PK, AUTO_INCREMENT |
| user_id | BIGINT | FK → users.id |
| project_id | BIGINT | FK → projects.id |
| operation_type | VARCHAR(50) | e.g. nl_query, summary, insight |
| ai_model | VARCHAR(50) | e.g. gpt-4o, gpt-4o-mini |
| tokens_input | INT | DEFAULT 0 |
| tokens_output | INT | DEFAULT 0 |
| estimated_cost_usd | DECIMAL(10,6) | |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** `idx_ut_user` (user_id), `idx_ut_project` (project_id), `idx_ut_created` (created_at), `idx_ut_operation` (operation_type)
**Partitioning:** RANGE by MONTH(created_at)

---

## 5. Caching Strategy (Redis)

| Cache Key Pattern | TTL | Invalidation |
|---|---|---|
| `schema:{data_source_id}:v{version}` | 1 hour | On schema re-sync |
| `schema:{data_source_id}:tables_list` | 1 hour | On schema re-sync |
| `ai:query_hash:{sha256}` | 15 min | Manual or TTL |
| `ai:summary:{project_id}:{type}` | 30 min | On new summary |
| `dq:report:{report_id}` | 1 hour | On new report |
| `user:session:{user_id}` | 24 hours | On logout |
| `ratelimit:{user_id}:{endpoint}` | 1 min (sliding) | Auto-expire |

**Invalidation strategy:** Event-driven. When a schema sync completes, publish a `SCHEMA_UPDATED` event that clears all related cache keys using Redis `DEL` with pattern matching via `SCAN`.

---

## 6. Authentication & RBAC

### JWT Structure
- **Access Token:** 15 minute TTL, contains user_id + roles + project_ids
- **Refresh Token:** 7 day TTL, stored hashed in `refresh_tokens` table
- Tokens delivered via httpOnly secure cookies (not localStorage)

### Role Hierarchy
| Role | Permissions |
|---|---|
| Admin | Full CRUD, user management, billing, all projects |
| Member | CRUD own projects, run queries, view insights |
| Viewer | Read-only access to assigned projects |

### Project-Level Roles
| Role | Permissions |
|---|---|
| admin | Full project control, manage members |
| editor | Run queries, trigger analysis, edit dictionary |
| viewer | Read-only access to results |

### Auth Flow
```
Login → Validate credentials → Issue access + refresh tokens
  → Store refresh_token hash in DB
  → Set httpOnly cookies

API Request → Extract JWT from cookie → Validate signature + expiry
  → Load roles from token claims → Check endpoint permission
  → If expired: Use refresh token to rotate
```

---

## 7. AI/LLM Integration Design

### Schema Representation for LLM
```
Format: Compact DDL-style text

TABLE customers (
  id BIGINT PK,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  segment VARCHAR(50) -- values: premium, standard, trial
)
-- Relationships: orders.customer_id → customers.id
```

### Chunking Strategy (for schemas > 100 tables)
1. Group tables by foreign key clusters (connected subgraphs)
2. Each chunk: max 25 tables with their relationships
3. First chunk includes a "schema overview" listing all table names
4. Subsequent chunks reference the overview for context

### NL → SQL Prompt Template
```
System: You are a SQL expert. Generate valid {db_type} SQL.
Rules:
- Use only tables and columns provided in the schema
- Always use table aliases
- Limit results to 100 rows unless specified
- Never use DELETE, DROP, UPDATE, INSERT
- Return ONLY the SQL query

Schema:
{schema_ddl}

User question: {natural_language_input}
```

### Cost Control
- Token budgets per user per day (configurable)
- Use gpt-4o-mini for simpler tasks (dictionary, column descriptions)
- Use gpt-4o for complex tasks (multi-table SQL, executive summaries)
- Cache identical queries by SHA-256 hash
- Track every call in `usage_tracking` table

---

## 8. Scalability Design

### Handling Large Databases (100+ tables)
- Schema extraction runs as async background job (never blocks API)
- Paginated schema browsing API: `/schema/tables?page=1&size=25`
- Schema stored with snapshot versioning — no re-extraction needed for browsing
- ER diagram computed server-side, sent as structured JSON (not computed in browser)

### Handling Millions of Rows
- Data quality analysis uses **sampling**: `SELECT * FROM table ORDER BY RAND() LIMIT 10000`
- For row counts: use `INFORMATION_SCHEMA.TABLES.TABLE_ROWS` (estimated, fast)
- NL → SQL queries execute with **timeout limits**: 30 second max
- Result preview limited to 50 rows, streamed

### Concurrent Users
- Stateless backend → unlimited horizontal scaling
- Connection pooling: HikariCP with 15 connections per instance
- Read replica handles schema browsing + report reads
- Redis distributes job queue across workers

### Scaling Milestones
| Users | Architecture |
|---|---|
| 0–500 | 2 backend pods, 1 worker, 1 MySQL, 1 Redis |
| 500–5K | 4 backend pods, 3 workers, MySQL + read replica, Redis cluster |
| 5K–50K | Split AI workers to separate service, add Kafka for reliable job delivery |
| 50K+ | Full microservices, per-tenant DB sharding, dedicated AI compute |

---

## 9. Security Design

| Threat | Mitigation |
|---|---|
| Password theft | bcrypt with cost factor 12 |
| DB credential exposure | AES-256-GCM encryption, key in AWS KMS / Vault |
| SQL injection (generated SQL) | Parameterized execution, READ-ONLY DB user for customer DBs |
| SQL injection (app queries) | JPA/Hibernate parameterized queries exclusively |
| Token theft | httpOnly + Secure + SameSite cookies, short-lived access tokens |
| Brute force | Rate limiting: 5 login attempts per minute per IP |
| Data exfiltration | Query result preview limited to 50 rows, no bulk export |
| Unauthorized access | RBAC checked at controller + service layer |
| External DB connections | SSL/TLS enforced, connection timeout 10s, query timeout 30s |
| Denial of service | API Gateway rate limits, request size limits (1MB max) |

### Security Headers
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
```

---

## 10. Deployment Architecture

### Docker Images
| Image | Base | Purpose |
|---|---|---|
| `ai-db-analyst/frontend` | nginx:alpine | Serve React SPA |
| `ai-db-analyst/backend` | eclipse-temurin:21-jre | Spring Boot API |
| `ai-db-analyst/worker` | eclipse-temurin:21-jre | Background job processing |

### Kubernetes Resources
```
Deployments:
  frontend    — 2 replicas, 256Mi memory
  backend     — 2-10 replicas (HPA on CPU 70%), 512Mi-1Gi memory
  worker      — 1-5 replicas (HPA on queue depth), 512Mi-1Gi memory

Services:
  frontend-svc    — ClusterIP
  backend-svc     — ClusterIP

Ingress:
  / → frontend-svc
  /api/* → backend-svc

ConfigMaps:
  app-config — DB host, Redis host, feature flags

Secrets:
  db-credentials — MySQL credentials
  redis-password — Redis auth
  openai-key — API key
  encryption-key — AES key for DB credentials
```

### CI/CD Pipeline (GitHub Actions)
```
Push to main →
  1. Run unit tests + integration tests
  2. Build Docker images
  3. Push to container registry
  4. Run database migrations (Flyway)
  5. Rolling deployment to staging
  6. Run smoke tests
  7. Manual approval gate
  8. Rolling deployment to production
```

### Environment Configuration
| Variable | Staging | Production |
|---|---|---|
| SPRING_PROFILES_ACTIVE | staging | production |
| DB_POOL_SIZE | 5 | 15 |
| REDIS_MAX_CONNECTIONS | 10 | 50 |
| OPENAI_RATE_LIMIT | 20/min | 100/min |
| JOB_WORKER_THREADS | 2 | 8 |
| LOG_LEVEL | DEBUG | INFO |

---

## 11. Tech Stack Summary

| Layer | Technology | Version |
|---|---|---|
| Frontend | React + Vite + TypeScript | React 18, Vite 5 |
| UI Components | shadcn/ui + Tailwind CSS | Latest |
| Charts | Recharts | 2.x |
| Backend | Spring Boot | 3.3.x |
| Language | Java | 21 LTS |
| ORM | Hibernate / Spring Data JPA | 6.x |
| Database | MySQL | 8.0+ |
| Cache / Queue | Redis | 7.x |
| AI/LLM | OpenAI API | GPT-4o |
| Auth | Spring Security + JWT | |
| Migration | Flyway | 10.x |
| Containers | Docker | |
| Orchestration | Kubernetes | 1.28+ |
| CI/CD | GitHub Actions | |
| Monitoring | Prometheus + Grafana | |
| Logging | ELK Stack or Loki | |

---

## 12. API Endpoint Design (RESTful)

```
POST   /api/v1/auth/login
POST   /api/v1/auth/signup
POST   /api/v1/auth/refresh
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/verify-otp
DELETE /api/v1/auth/logout

GET    /api/v1/projects
POST   /api/v1/projects
GET    /api/v1/projects/{id}
PUT    /api/v1/projects/{id}
DELETE /api/v1/projects/{id}
GET    /api/v1/projects/{id}/members
POST   /api/v1/projects/{id}/members

POST   /api/v1/data-sources
GET    /api/v1/data-sources/{id}
POST   /api/v1/data-sources/{id}/test-connection
POST   /api/v1/data-sources/{id}/sync

GET    /api/v1/schema/{data_source_id}/tables
GET    /api/v1/schema/{data_source_id}/tables/{table_id}/columns
GET    /api/v1/schema/{data_source_id}/relationships
GET    /api/v1/schema/{data_source_id}/er-diagram

POST   /api/v1/queries/nl-to-sql
GET    /api/v1/queries/history

POST   /api/v1/data-quality/{data_source_id}/analyze
GET    /api/v1/data-quality/reports/{report_id}

POST   /api/v1/summaries/generate
GET    /api/v1/summaries/{project_id}

GET    /api/v1/insights/{project_id}
POST   /api/v1/insights/generate

GET    /api/v1/dictionary/{data_source_id}
PUT    /api/v1/dictionary/{column_id}

GET    /api/v1/jobs/{id}/status
GET    /api/v1/jobs/project/{project_id}

GET    /api/v1/usage/{project_id}
GET    /api/v1/usage/me
```

