# Repository Guidelines

## Project Structure & Module Organization
- `flights_eda_engineering.ipynb`: main notebook for EDA, cleaning, and feature engineering (FE1–FE6).
- `data/`: local data only (not versioned). Subfolders: `flights/` (12 monthly CSVs for 2024), `dims/` (lookups), `output/` (parquet exports).
- `docs/`: BTS data dictionary PDF and references.
- `instructions/`: project prompt and requirements.

## Build, Test, and Development Commands
- Run notebook UI: `jupyter lab` (or `code .` then open the notebook). On macOS you can also `open flights_eda_engineering.ipynb`.
- Headless via Makefile:
  - `make test-notebook` — fast smoke test (`TEST_MODE=1`, ~50k rows per CSV), writes `executed_test.ipynb` (ignored).
  - `make run-notebook` — full data run (all rows), writes `executed.ipynb` (ignored).
  - `make clean-output` — removes `data/output/*.parquet` and `executed*.ipynb`.
- Export path: notebook writes to `data/output/flights_2024_clean_sampled.parquet`.
- Optional quick check:
  - `python - <<'PY'\nimport pandas as pd; print(pd.read_parquet('data/output/flights_2024_clean_sampled.parquet').head(3))\nPY`

## Coding Style & Naming Conventions
- Python 3 + Pandas; follow PEP8 and readable, vectorized Pandas patterns.
- Column names: lower_snake_case; one objective per cell preceded by a markdown title.
- Config: keep tweakables (thresholds, sample rate, paths) in the “Globals & Configuration” cell.
- Previews: end cells with concise outputs (e.g., `.head(3)`).

## Testing Guidelines
- Use lightweight assertions and sanity checks inside the notebook (row counts before/after, null rates, distribution plots).
- Validate FE1 rollover cases and FE5 airline joins with spot checks (e.g., `AA → American Airlines`, `WN → Southwest Airlines`).
- Re-run end-to-end after changing globals to confirm determinism.

## Commit & Pull Request Guidelines
- Commits: concise, imperative, scoped (e.g., `notebook: add FE6 stratified sampling`, `data: update dims`).
- PRs: include summary, key changes, sample preview (3–5 rows), and output location. Note any schema changes and cleanup drops.
- Do not commit large raw data; keep outputs in `data/output/` and reference paths in descriptions.

## Security & Configuration Tips
- Treat `data/` as local-only; verify paths before running. Avoid embedding secrets in notebooks. Prefer relative paths and reproducible settings (seeded sampling).
 - TEST_MODE semantics: `TEST_MODE=1` enables limited row reads and disables plots; otherwise full processing.
