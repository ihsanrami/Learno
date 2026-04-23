# Learno Backend Test Suite

## Quick start

```bash
cd backend_fixed

# Install runtime + dev dependencies
pip install -r requirements.txt -r requirements-dev.txt

# Run all tests
pytest tests/ -v
```

## Run a specific file

```bash
pytest tests/test_message_splitter.py -v
pytest tests/test_image_proxy.py -v
pytest tests/test_curriculum.py -v
pytest tests/test_curriculum_endpoints.py -v
pytest tests/test_chapter_generator.py -v
```

## Run a single test

```bash
pytest tests/test_curriculum.py::test_curriculum_has_20_entries -v
```

## What each file covers

| File | What it tests |
|------|---------------|
| `test_message_splitter.py` | Sentence splitting, grouping, delay calc, image position, emoji detection |
| `test_image_proxy.py` | DALL-E download→cache (sync & async), error fallback, cleanup |
| `test_curriculum.py` | CURRICULUM dict structure (20 entries, 6 topics each), all helper functions |
| `test_curriculum_endpoints.py` | HTTP endpoints `/grades`, `/subjects`, `/topics`, error responses |
| `test_chapter_generator.py` | GPT-4 mocked generation, cache hit/miss, fallback on failure |

## Adding a new test

1. Pick the file that matches the feature area (or create `tests/test_<feature>.py`)
2. Name your function `test_<what_it_verifies>()`
3. Mock any external calls (OpenAI, httpx) — never make real network calls in tests
4. Run `pytest tests/ -v` to confirm everything passes

## Important: no real API calls

All OpenAI and HTTP calls are mocked. Tests run in < 1 second and require no API keys beyond the fake one injected in `conftest.py`.

## Environment

`conftest.py` automatically sets `OPENAI_API_KEY=sk-test-not-real` before any app import, so no `.env` file is required to run tests.
