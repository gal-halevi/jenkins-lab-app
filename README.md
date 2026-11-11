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
src/labapp/            app.py (routes), stats.py (pure logic)
tests/                 pytest; tests marked @pytest.mark.slow are for the nightly run
ci/                    the build, as scripts: Jenkins and your machine run the same ones
  common.sh            sourced by every script: repo root, venv location, helpers
  shellcheck.sh        lint the ci/ scripts themselves
  setup.sh             fresh venv from the lock, install the package, pip check
  lint.sh              ruff check + ruff format --check
  test.sh              fast suite, JUnit report to $PYTEST_REPORT (default reports/pytest-report.xml)
  package.sh           wheel into dist/ (cleared first)
Jenkinsfile            orchestration only: stages, reports, artifacts
pyproject.toml         package metadata, build backend, pytest and ruff config
requirements.txt       runtime dependencies, fully pinned (the lock)
requirements-dev.txt   + test, lint and build tools, fully pinned
.python-version        the Python version setup.sh uses
.shellcheckrc          shellcheck settings for editor, terminal and CI
```

## Run locally

Needs the Python version in `.python-version` (`python3.12` on PATH, or set `PYTHON=/path/to/python`)
and `shellcheck`. Run from anywhere; the scripts find the repo root themselves.

```bash
ci/shellcheck.sh
ci/setup.sh          # recreates .venv from scratch every time
ci/lint.sh
ci/test.sh
ci/package.sh        # dist/labapp-<version>-py3-none-any.whl

.venv/bin/flask --app labapp run                       # dev server on :5000
.venv/bin/gunicorn -b 0.0.0.0:8000 'labapp:create_app()'   # how it runs when deployed
```

## Dependencies and the lock

`pyproject.toml` lists what the package **needs**, as ranges; they travel inside the wheel.
`requirements*.txt` are the **lock**: every package, transitive ones included, at the exact version
that was tested. CI installs the lock with `--no-deps`, so nothing outside it can get in, and
`pip check` fails the build if the lock is incomplete or inconsistent.

Build tools (setuptools, setuptools-scm) are pinned in the dev lock too. Builds run without isolation
(`pip install --no-build-isolation`, `python -m build --no-isolation`), so they use those pins instead
of downloading the newest versions. That is also why `setup.sh` installs in two steps: the lock first,
then the package, which needs setuptools to already be in the venv.

**Adding a package**: start from the current lock, so nothing else changes:

```bash
python3.12 -m venv --clear /tmp/lockvenv
/tmp/lockvenv/bin/pip install -r requirements-dev.txt <new-package>
/tmp/lockvenv/bin/pip freeze | grep -vxFf <(cat requirements.txt requirements-dev.txt)
```

The output is exactly the lines to add: to `requirements.txt` for a runtime dependency (and to
`dependencies` in `pyproject.toml`), to `requirements-dev.txt` for a tool. If it shows an existing
package at a new version, something changed that you didn't ask for: look before committing.

**Upgrading**: a deliberate change of its own, in its own commit. Install the top-level packages
unpinned in a clean venv, freeze, and review the diff. Prefer releases that are a few weeks old.

## Versioning

The version comes from **git tags**, via setuptools-scm; there is no version number in any file.

| State | Version |
|---|---|
| exactly on tag `v0.1.0` | `0.1.0` |
| 2 commits after it | `0.1.1.dev2+g<hash>` |
| uncommitted changes | `…+g<hash>.d<date>` |

Release tags are annotated (`git tag -a v0.2.0 -m "Release 0.2.0"`), pushed by name, and never moved
or deleted once pushed.

Check the version on each layer:

```bash
.venv/bin/python -m setuptools_scm                                  # computed from git
.venv/bin/python -c "from importlib.metadata import version; print(version('labapp'))"   # installed
unzip -p dist/labapp-*.whl '*.dist-info/METADATA' | grep '^Version'  # inside the wheel
```

`/health` reports the installed version.
