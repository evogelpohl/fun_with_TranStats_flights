
# Simple task runner for this repo

.PHONY: help data data-month test-notebook run-notebook clean-output open-notebook git-sync git-status

YEAR ?= 2024
MONTHS := 1 2 3 4 5 6 7 8 9 10 11 12
ZIP_BASE := https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_$(YEAR)_

help:
	@echo "Targets:"
	@echo "  make data            - Download and unzip all months ($(YEAR)) into data/flights/"
	@echo "  make data-month M=4  - Download and unzip a single month (M=1..12)"
	@echo "  make test-notebook   - Headless run with TEST_MODE=1 (fast smoke test)"
	@echo "  make run-notebook    - Headless run (full data; slower)"
	@echo "  make clean-output    - Remove generated parquet and executed notebooks"
	@echo "  make open-notebook   - Open flights_eda_engineering.ipynb in default app"
	@echo "  make git-sync MSG=.. - Add, commit, pull --rebase, and push current branch"
	@echo "  make git-status      - Show repo status and remotes"

data:
	@mkdir -p data/flights data/dims data/output
	@for m in $(MONTHS); do \
	  echo "Downloading month $$m..."; \
	  curl -L -o "data/flights/On_Time_1987_present_$(YEAR)_$$m.zip" \
	    "$(ZIP_BASE)$$m.zip"; \
	  unzip -o "data/flights/On_Time_1987_present_$(YEAR)_$$m.zip" -d data/flights; \
	  rm -f "data/flights/On_Time_1987_present_$(YEAR)_$$m.zip"; \
	done

data-month:
	@mkdir -p data/flights
	@if [ -z "$(M)" ]; then echo "Usage: make data-month M=4"; exit 1; fi
	curl -L -o "data/flights/On_Time_1987_present_$(YEAR)_$(M).zip" \
	  "$(ZIP_BASE)$(M).zip"
	unzip -o "data/flights/On_Time_1987_present_$(YEAR)_$(M).zip" -d data/flights
	rm -f "data/flights/On_Time_1987_present_$(YEAR)_$(M).zip"

test-notebook:
	@echo "Running notebook in TEST_MODE (limited rows, no plots)..."
	TEST_MODE=1 jupyter nbconvert \
	  --to notebook --execute flights_eda_engineering.ipynb \
	  --output executed_test.ipynb --ExecutePreprocessor.timeout=3600

run-notebook:
	@echo "Running notebook on full data..."
	jupyter nbconvert \
	  --to notebook --execute flights_eda_engineering.ipynb \
	  --output executed.ipynb --ExecutePreprocessor.timeout=14400

clean-output:
	rm -f data/output/*.parquet executed*.ipynb

open-notebook:
	@which open >/dev/null 2>&1 && open flights_eda_engineering.ipynb || \
	(which xdg-open >/dev/null 2>&1 && xdg-open flights_eda_engineering.ipynb || true)

# Git helpers
git-status:
	@git branch --show-current || true
	@git status -sb || true
	@git remote -v || true

git-sync:
	@branch=$$(git rev-parse --abbrev-ref HEAD); \
	  echo "Branch: $$branch"; \
	  if [ -z "$(MSG)" ]; then \
	    echo "Usage: make git-sync MSG='your commit message'" 1>&2; exit 1; \
	  fi; \
	  git add -A; \
	  git commit -m "$(MSG)" || echo "No changes to commit"; \
	  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then \
	    echo "Upstream set; pulling with rebase..."; \
	    git pull --rebase; \
	    echo "Pushing to upstream..."; \
	    git push; \
	  else \
	    echo "No upstream set; pushing and setting upstream to origin/$$branch"; \
	    git push -u origin $$branch; \
	  fi
