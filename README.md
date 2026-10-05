# Lob City 

## Team quality, spectacle, and NBA home attendance

This repository contains the data and R code for a sports economics project on the **Los Angeles Clippers and the NBA from 1999-00 through 2016-17**.

The project asks whether NBA home attendance is more consistently associated with **team quality**, measured by winning percentage, or with entertainment-related playing characteristics, measured by **dunks per game** and **pace**. It then applies the league-wide model back to the Los Angeles Clippers during the Lob City era.

## Main empirical specifications

The dependent variable is average home attendance per game.

1. **Model 1:** attendance ~ winning percentage
2. **Model 2:** attendance ~ winning percentage + dunks per game + pace
3. **Model 3:** attendance ~ winning percentage + dunks per game + pace + season controls

The league dataset contains **535 team-season rows** from 1999-00 through 2016-17. The regressions use **534 observations** because one row contains a missing regression variable.

## Repository structure

```text
.
├── README.md
├── DATA_SOURCES.md
├── Project_1_Sports_Analytics.Rproj
├── install_packages.R
├── R/
│   ├── 01_build_league_data.R
│   ├── 02_final_analysis.R
│   ├── 03_part1_figures.R
│   └── run_all.R
└── data/
    └── cleaned/                    # committed analysis-ready CSVs
```

## Reproduce the reported analysis

### 1. Open the RStudio project

Open `Project_1_Sports_Analytics.Rproj` in RStudio so the repository root is the working directory.

### 2. Install required packages

Run once:

```r
source("install_packages.R")
```

### 3. Reproduce the figures, regressions, and fitted-attendance analysis

```r
source("R/run_all.R")
```

The main reproduction workflow uses the analysis-ready CSV files committed in `data/cleaned/`. Output folders are created automatically.

## Key outputs

The scripts create:

- `output/figures/clippers_share_la_value.png`
- `output/figures/clippers_historical_stacked_graph.png`
- `output/figures/clippers_gate_revenue.png`
- `output/figures/clippers_actual_vs_fitted_model3.png`
- `output/tables/hypothesis_table.png`
- `output/tables/part2_regression_results.png`
- `output/tables/lob_city_fitted_gap.csv`

## Data sources

The analysis uses:

- **Basketball-Reference / Sports Reference LLC** for team performance, pace, and shooting/dunk data.
- **Rodney Fort's sports business data collection** for attendance and archived NBA business data.
- **Forbes data archived through Rodney Fort's collection** for franchise values and team financial information.
- **U.S. Bureau of Labor Statistics** CPI-U data for inflation adjustments.
- **U.S. Census Bureau** for the Los Angeles metropolitan population statistic used in the written report.

See [`DATA_SOURCES.md`](DATA_SOURCES.md) for links and details.

## Reproducibility notes

- All code uses paths relative to the repository root.
- The league analysis data are stored as six `nba_part_*.csv` files in `data/cleaned/`; `R/02_final_analysis.R` combines them automatically.
- `R/01_build_league_data.R` documents how the league dataset was assembled from the original source downloads. Those external source downloads are not required to reproduce the reported models because the resulting cleaned dataset is committed here.
- The 2011-12 NBA season was shortened to 66 games. The dependent variable is attendance per home game, which normalizes for the shorter schedule.
- Model 3 fitted values for the Clippers are in-sample fitted values, not out-of-sample forecasts.
