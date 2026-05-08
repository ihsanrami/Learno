# Learno Backend — Performance Guide

## Optimizations Applied

### Database Indexes
Added explicit SQLAlchemy `Index()` declarations on frequently queried columns:

| Table | Column(s) | Query pattern |
|---|---|---|
| `child_profiles` | `parent_id` | List children by parent |
| `learning_sessions` | `child_id` | All analytics queries |
| `learning_sessions` | `(child_id, started_at)` | Time-range analytics |
| `achievements` | `child_id` | Achievement queries |
| `refresh_tokens` | `expires_at` | Token cleanup queries |

### Query Optimizations
- **`_calculate_streak()`**: Replaced 365-query loop with a single `DISTINCT date(started_at)` query. This was the worst bottleneck — O(365) DB round-trips → O(1).
- **`get_child_overview()`**: Loads all sessions in one query, computes today/all-time stats in Python instead of issuing multiple date-filtered queries.
- **`get_weekly_activity()`**: Replaced 7 per-day queries with a single date-range query, grouping in Python.

### Caching
The chapter cache (`_chapter_cache`) is now a bounded LRU cache:
- **Max size**: 100 entries (curriculum has 80 topics total)
- **TTL**: 24 hours — chapters expire and regenerate
- **Eviction**: LRU (OrderedDict) — oldest entry removed when full
- **Stats**: Available at `GET /health` → `data.chapter_cache`

Cache hit rate target: **> 70%** after warm-up. Each cache hit saves ~2–8s of GPT-4 latency.

### Response Compression
GZip middleware enabled for all responses > 1 KB:
```python
app.add_middleware(GZipMiddleware, minimum_size=1000)
```
Typical compression ratio: 60–80% for JSON payloads.

### Rate Limiting
All lesson/session endpoints now have IP-based rate limits (slowapi):

| Endpoint | Limit |
|---|---|
| `POST /session/start` | 30/minute |
| `POST /session/end` | 60/minute |
| `POST /lesson/continue` | 60/minute |
| `POST /lesson/respond` | 60/minute |
| `POST /lesson/silence` | 30/minute |
| `POST /auth/register` | 10/minute |
| `POST /auth/login` | 20/minute |
| `POST /auth/refresh` | 30/minute |

### Logging
- Structured log format: `timestamp level logger message`
- Slow request warning logged for any request > 1 second (excluding GPT-4 calls)
- Startup confirmed with log entry

## Performance Targets

| Metric | Target |
|---|---|
| API p95 response (non-GPT) | < 500ms |
| Concurrent users | 100+ |
| Memory per instance | < 512MB |
| GPT-4 cache hit rate | > 70% (after warm-up) |
| App startup | < 3s |
| Image load | < 2s |

## Monitoring

### Health Check
```
GET /health
GET /api/v1/health
```
Returns: `status`, `version`, `uptime_seconds`, `chapter_cache` stats (size, hits, misses, hit_rate_pct).

### Slow Request Log
Any request taking > 1s emits a `WARNING` log:
```
SLOW REQUEST 1234ms POST /api/v1/lesson/continue
```

### Cache Hit Rate
Monitor `chapter_cache.hit_rate_pct` at `/health`. If below 70% after initial warm-up, investigate whether TTL is too short or cache is being cleared unexpectedly.

## Scaling

### Horizontal Scaling
- The app is stateless except for the in-memory chapter cache.
- When running multiple instances, each instance maintains its own cache — acceptable since GPT-4 calls are idempotent and the cache warms up quickly.
- For true shared cache at scale, replace `_chapter_cache` with Redis.

### Database
- Currently uses SQLite (development). For production with 100+ concurrent users, migrate to PostgreSQL.
- All indexes are already declared and will apply to PostgreSQL automatically.
- Consider connection pooling: set `pool_size=10, max_overflow=20` in `create_engine`.

### Example production engine config
```python
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
)
```
