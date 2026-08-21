# AGENTS.md

## Project

`ecommerce-price-tracker` — a Python service that tracks product prices across
e-commerce sites. Greenfield: this is the first commit. `src/` is empty; the
stack below is declared in `pyproject.toml` but not yet wired.

## Tooling: uv

This project is managed with **uv** for everything — installation, sync,
script execution, and tool invocation. Do not call `pip`, `python`, `pytest`,
`ruff`, or any project tool directly; always go through `uv`.

- Install / sync deps: `uv sync`
- Run a command in the project env: `uv run <cmd>` (e.g. `uv run pytest`,
  `uv run ruff check .`, `uv run python -m <pkg>`)
- Add a dependency: `uv add <pkg>` (dev deps: `uv add --dev <pkg>`)
- Run a one-off without polluting the env: `uvx <tool>`

There is no `uv.lock` yet. Commit one once `uv sync` produces it.

## Stack (declared, not yet wired)

- **API**: FastAPI + uvicorn[standard], pydantic + pydantic-settings
- **SQL**: SQLAlchemy 2 (async), asyncpg, Alembic
- **Document/cache**: MongoDB via motor + pymongo, Redis
- **Workflow orchestration**: Prefect 2
- **Scraping**: beautifulsoup4, httpx, Playwright
- **Storage**: boto3
- **Tests**: pytest, pytest-asyncio

No linter, typechecker, or formatter is configured. No `[tool.*]` sections
exist in `pyproject.toml`. Add them as needed; do not assume defaults.

## Environment

- `.python-version` pins **3.14**; `pyproject.toml` requires **>=3.12.3**.
  Match `pyproject.toml` when bumping the version floor.
- `.env` is gitignored and currently empty. Pydantic-settings is the loader;
  never read `os.environ` directly.

## Layout

- Source goes under `src/` (no `__init__.py`, no module, no entrypoint yet).
- DB migrations: Alembic is the only declared tool — set it up under
  `src/<pkg>/migrations/`, not at the repo root.
- Prefect flows: keep them in their own module (`flows/` or `workflows/`)
  so they are importable as a package and discoverable by `prefect deploy`.

## Commands

No scripts, Makefile, or `task` runner is configured. Until they are, every
command goes through uv:

- **Sync deps first**: `uv sync` (regenerates `.venv`).
- **Run a single test**: `uv run pytest <path/to/test_file.py>::<test_name>`.
- **Run the API locally**: `uv run uvicorn <pkg>.main:app --reload` (module
  does not exist yet).
- **Prefect dev**: `uv run prefect server start` for the orchestrator UI.

If you add a Taskfile, Makefile, or `pyproject` scripts block, document the
shortcut commands here.

## CI (stub)

`.github/workflows/CI.yml` exists as a 0-byte placeholder. Fill in at least:

- `uv sync` on Python from `.python-version`
- `uv run pytest` (with services stubbed or a service matrix for postgres/redis/mongo)
- Lint/typecheck steps once `[tool.ruff]` / `[tool.mypy]` are added
- Prefect is not exercised in CI; do not block on it.

## Code style

- Functions: 4–20 lines. Split if longer.
- Files: under 500 lines. One responsibility per module.
- Names: specific and unique. Avoid `data`, `handler`, `Manager`. Aim for
  names that return <5 grep hits.
- Types: explicit. No `any`, no untyped functions, no bare `dict`/`list`
  in public signatures — use `TypedDict` or pydantic models.
- No duplication. Extract shared logic into a function/module.
- Early returns. Max 2 levels of indentation.
- Exception messages include the offending value and the expected shape:
  `raise ValueError(f"got {price!r}, expected Decimal >= 0")`.

## Comments and docstrings

- Comments capture WHY, not WHAT. Drop `// increment counter` style.
- Keep your own comments across refactors — they carry intent and provenance.
- Reference issue numbers or commit SHAs when a line exists because of a
  specific bug or upstream constraint.
- Public functions get a docstring with intent plus one usage example.

## Tests

- Framework: pytest with `pytest-asyncio` (declared, no `asyncio_mode` set
  yet — default is `strict`, so mark async tests with `@pytest.mark.asyncio`).
- Every new function gets a test. Bug fixes get a regression test.
- Mock external I/O (HTTP, DB, browser, S3) with named fake classes, not
  inline stubs. Wrap each third-party SDK behind a thin project-owned
  interface so fakes slot in.
- Tests must be F.I.R.S.T.: fast, independent, repeatable,
  self-validating, timely.
- Playwright tests need the browser installed (`playwright install`).
  Mark slow/expensive suites and skip them in the default CI run.

## Dependencies

- Inject through constructor or parameter, not via global/import.
- Wrap third-party libraries behind a thin interface owned by this project.
  Tests depend on the interface, not the SDK.

## Logging

- Structured JSON for debug/observability logs.
- Plain text only for user-facing CLI output.

## Formatting

- No formatter is configured yet. When added, use the language default
  (`black` or `uv run ruff format`) and stop debating style.

## Branching & PR workflow

`main` is protected. **Do not commit, push, or force-push directly to
`main`.** Every change goes through a feature branch and a pull request.

### Reviewers

`.github/CODEOWNERS` declares `@mpraes` as the default reviewer for the
whole repo. GitHub auto-requests review from code owners on every PR, so
your PRs land in your review queue automatically. When collaborators
join, add per-path owners there (e.g. `/src/scrapers/ @mpraes @other`).

### Rules on `main`

- Pull request required to merge.
- 1 approving review required (you cannot count your own approval).
- `CI` status check must pass; the branch must be up to date with `main`.
- Stale approvals are dismissed on new pushes.
- Force-pushes are blocked; the branch cannot be deleted.
- Linear history required (squash or rebase merges).
- Admins (you) can bypass the rules — keep that to emergencies only.

These are set via the GitHub API; see `scripts/setup-branch-protection.sh`
to (re)apply them, or run the documented `gh api` call manually.

#### Solo-dev caveat

GitHub does not count an approval from the PR author toward the required
review count. While the project is solo, no one can satisfy the
"1 approval" rule, so merges **must** use admin bypass:

```bash
gh pr merge --squash --delete-branch --admin
```

Drop `--admin` from the workflow once a second reviewer exists. The
helper `scripts/new-feature.sh` already prints the right command.

### Naming

- `<type>/<short-kebab-summary>` — e.g. `feat/scrape-pagination`,
  `fix/redis-port-conflict`, `chore/ci-workflow`, `docs/readme-quickstart`.
- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`,
  `build`, `ci`.

### Lifecycle (do this from the terminal)

```bash
# 1. Start a new branch off main
scripts/new-feature.sh feat/my-change

# 2. Make changes, then commit
git add -A
git commit -m "feat: short imperative summary"

# 3. Push the branch
git push -u origin feat/my-change

# 4. Open the PR (--fill uses commit messages for title/body)
gh pr create --base main --head feat/my-change --reviewer @me --fill

# 5. After green CI, merge (squash keeps linear history)
#    Use --admin while the project is solo; drop it once a second reviewer exists.
gh pr merge --squash --delete-branch --admin
```

The helper at `scripts/new-feature.sh` enforces a clean working tree,
syncs `main`, and prints the next steps. Prefer it over typing the
commands by hand.

### Commit messages

- Imperative mood, ≤72 chars on the subject line.
- Body explains *why*, not *what*; wrap at 72 cols.
- Reference issues with `#123` when relevant.
