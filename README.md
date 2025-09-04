# BTS On‑Time Flights — EDA and Feature Engineering

This repository prepares the U.S. BTS On‑Time Performance data (2024 monthly CSVs) into an analysis‑ready Parquet for BI and downstream analytics. Work is centered in a single Jupyter notebook that performs cleaning, type casting, feature engineering, validation, and export.

## Quickstart
- Prereqs: Python 3.10+, pandas, pyarrow, jupyterlab, seaborn, matplotlib.
  - Example: `pip install pandas pyarrow jupyterlab seaborn matplotlib`
- Data layout:
  - `data/flights/` — 12 CSVs for 2024 (one per month)
  - `data/dims/T_MASTER_CORD.csv` — airport coordinates (use latest rows only)
  - `data/dims/L_AIRLINE_ID.csv` — airline ID lookup
  - `docs/bts_ontime_flight_perf_data_dictionary.pdf` — field definitions
- Run the notebook:
  - macOS: `open flights_eda_engineering.ipynb` (or `jupyter lab` and open it)
  - Execute cells top‑to‑bottom; output is written to `data/output/flights_2024_clean_sampled.parquet`.
  - Make targets (headless):
    - `make test-notebook` → fast smoke test; sets `TEST_MODE=1`, reads ~50k rows per CSV and writes `executed_test.ipynb` (ignored).
    - `make run-notebook` → full data run; reads all rows and writes `executed.ipynb` (ignored).
    - `make clean-output` → removes `data/output/*.parquet` and any `executed*.ipynb`.
- Verify output:
  - `python - <<'PY'
import pandas as pd; print(pd.read_parquet('data/output/flights_2024_clean_sampled.parquet').head(3))
PY`

## Download Data from BTS
Create folders and download monthly On‑Time Performance zips from BTS TranStats, then unzip into `data/flights/`.

```bash
mkdir -p data/flights data/dims data/output

# Example: download a single month (April 2024)
curl -L -o data/flights/On_Time_1987_present_2024_4.zip \
  "https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2024_4.zip"
unzip -o data/flights/On_Time_1987_present_2024_4.zip -d data/flights

# Download all months (Jan–Dec 2024)
for m in {1..12}; do \
  curl -L -o "data/flights/On_Time_1987_present_2024_${m}.zip" \
    "https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2024_${m}.zip"; \
  unzip -o "data/flights/On_Time_1987_present_2024_${m}.zip" -d data/flights; \
  rm "data/flights/On_Time_1987_present_2024_${m}.zip"; \
done
```

Expected extracted filenames resemble:
- `On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2024_4.csv`

Place lookup tables in `data/dims/`:
- `T_MASTER_CORD.csv` (airport coordinates)
- `L_AIRLINE_ID.csv` (airline IDs and names)

## What the Notebook Does
- Standardizes columns to lower_snake_case and casts dtypes per the BTS dictionary.
- Cleans rows missing critical delay fields and prunes columns with ≥80% nulls (configurable).
- Feature engineering:
  - FE1: daypart_sched and daypart_actual with midnight‑rollover logic.
  - FE2: origin_tier by airport volume (Top 20%, Next 50%, Bottom 30%).
  - FE3: is_late_departure, is_on_time_departure from DepDel15.
  - FE4: origin/dest lat/long via SCD‑latest airport dim join.
  - FE5: airline_name via IATA code parsed from airline dim description.
  - FE6: 10% stratified sample by month, IATA code, and DepDel15 (configurable).

## Notes & Troubleshooting
- Large CSVs: the notebook loads as string first, then casts to reduce memory churn.
- Configure thresholds and sampling in the “Globals & Configuration” cell.
- TEST_MODE:
  - `TEST_MODE=1` reduces per‑file reads via `READ_NROWS` for quick runs and suppresses plots.
  - `TEST_MODE=0` (default) processes all rows in all 12 monthly CSVs.
- Logs: `logs/` is ignored by git; you can capture runs with `... | tee -a logs/run_$(date +%F_%H%M%S).log`.
- If Parquet writes fail, ensure `pyarrow` is installed and the `data/output/` directory exists.

## Contributing
Contributions welcome. See AGENTS.md for structure, conventions, testing tips, and PR guidelines.
