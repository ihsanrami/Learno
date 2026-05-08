# Database Migrations

## Current Approach

The backend uses **SQLAlchemy `Base.metadata.create_all()`** to initialise the schema
on every startup.  This is safe because `create_all()` is idempotent — it only creates
tables that do not already exist and never alters or drops existing tables.

Called in `app/main.py` inside the `lifespan` context manager:

```python
Base.metadata.create_all(bind=engine)
```

**Appropriate for:** development, staging, and small production deployments where the
database starts empty or only adds new tables between releases.

**Not appropriate for:** schema changes that alter or drop existing columns/tables —
those require a proper migration tool (see below).

---

## Switching to Alembic (Recommended for Production)

When you need to rename columns, add NOT NULL columns to populated tables, or make any
destructive schema change, migrate to Alembic:

```bash
pip install alembic
alembic init alembic
```

Point `alembic/env.py` at the app's `Base` and `DATABASE_URL`:

```python
from app.database.base import Base
from app.config import settings
target_metadata = Base.metadata
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)
```

Then generate and apply migrations normally:

```bash
alembic revision --autogenerate -m "describe the change"
alembic upgrade head
```

---

## Breaking Schema Changes Procedure

1. Write the Alembic migration and review the generated SQL carefully.
2. Test on a copy of the production database.
3. Take a database backup immediately before deploying.
4. Deploy the new backend version **and** run `alembic upgrade head` in the same
   release window to keep schema and code in sync.
5. Verify the application starts cleanly and run the test suite against the
   migrated database.

---

## Current Schema Version

Schema is managed by `create_all()`.  No Alembic history yet.  All tables defined in
`app/auth/models.py`:

| Table              | Key indexes                                        |
|--------------------|----------------------------------------------------|
| parents            | email (unique), id                                 |
| child_profiles     | id, parent_id                                      |
| learning_sessions  | id, child_id, (child_id, started_at)               |
| daily_goals        | id, child_id                                       |
| achievements       | id, child_id                                       |
| refresh_tokens     | id, token_hash (unique), expires_at                |
