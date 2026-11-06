# jenkins-lab-app

A small HTTP service that exists to be built, tested, packaged and deployed by Jenkins
in the course lab. The app is deliberately boring; the pipeline is the point.

## API

| Route | Returns |
|---|---|
| `GET /health` | `{"status": "ok", "version": "<installed package version>", "host": "<hostname>"}` |
| `GET /api/v1/stats?numbers=1,2,3` | count, min, max, mean, median; `400` with `{"error": ...}` on bad input |

Setting `LABAPP_FORCE_UNHEALTHY=1` makes `/health` return `500`, for practicing automatic rollback.

## Layout

```
src/labapp/        app.py (routes), stats.py (pure logic)
tests/             pytest; tests marked @pytest.mark.slow are for the nightly run
pyproject.toml     package metadata, pytest and ruff config
requirements.txt   runtime dependencies, fully pinned
requirements-dev.txt  + test, lint and build tools, fully pinned
```

## Run locally

Python 3.12+.

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt -e . --no-deps

ruff check . && ruff format --check .     # lint
pytest -m "not slow"                      # fast suite
pytest                                    # everything
python -m build                           # dist/labapp-<version>-py3-none-any.whl + sdist

flask --app labapp run                    # dev server on :5000
gunicorn -b 0.0.0.0:8000 'labapp:create_app()'   # how it runs when deployed
```

## Updating dependencies

Pins include transitive dependencies, so a build next month installs exactly what was tested today.
To update: in a clean venv, install the top-level packages at their new versions, then regenerate
`requirements.txt` with `pip freeze`, and do the same for the dev tools.

## Versioning

`version` in `pyproject.toml` is a static `0.1.0` for now. `/health` reports whatever version is in
the installed package, so once the pipeline stamps a real version into the build, it shows up there.
