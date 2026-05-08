# Learno Backend

FastAPI educational backend with JWT authentication and child profile management.

## Quick Start

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API docs: http://localhost:8000/docs

## Environment Variables

| Variable | Default | Notes |
|---|---|---|
| `OPENAI_API_KEY` | — | Required for AI lesson generation |
| `DATABASE_URL` | `sqlite:///./learno.db` | Use PostgreSQL URL in production |
| `JWT_SECRET_KEY` | random (unsafe) | **Must** be set to a stable secret in production |
| `JWT_ALGORITHM` | `HS256` | |

> **Production**: always set `JWT_SECRET_KEY` to a long random string, e.g. `openssl rand -hex 32`. Without it, all tokens are invalidated on restart.

## Authentication Endpoints

All auth endpoints are under `/api/v1/auth`.

### Register

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"parent@example.com","password":"MyPassword1!","full_name":"Ahmed Ali"}'
```

### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"parent@example.com","password":"MyPassword1!"}'
# Returns: {"access_token":"...","refresh_token":"...","token_type":"bearer"}
```

### Refresh Token

```bash
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<your-refresh-token>"}'
```

### Logout

```bash
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<your-refresh-token>"}'
```

### Get Current Parent

```bash
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer <access-token>"
```

## Children Endpoints

All under `/api/v1/children` — require `Authorization: Bearer <access-token>`.

```bash
# List children
curl http://localhost:8000/api/v1/children/ -H "Authorization: Bearer <token>"

# Create child
curl -X POST http://localhost:8000/api/v1/children/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Ali","age":7,"grade":"second","avatar":"fox"}'

# Select child for session
curl -X POST http://localhost:8000/api/v1/children/1/select \
  -H "Authorization: Bearer <token>"
```

Valid grades: `kindergarten`, `first`, `second`, `third`, `fourth`. Age range: 4–10.

## Running Tests

```bash
pip install -r requirements.txt -r requirements-dev.txt
pytest tests/ -v
```

Tests use an in-memory SQLite database — no real OpenAI calls are made.

## COPPA Compliance

Children's profiles collect only: name, age, grade, avatar. No email, no password, no PII beyond the parent's account.
