# Data sources

This repository includes the analysis-ready CSV files used to reproduce the reported results. The original external source downloads are documented below.

## Basketball-Reference / Sports Reference LLC

Used for NBA team wins, losses, games played, pace, and shooting/dunk statistics.

- Website: https://www.basketball-reference.com/
- Organization: Sports Reference LLC
- Seasons used: 1999-00 through 2016-17

The committed league analysis data are stored as six `nba_part_*.csv` files in `data/cleaned/`. `R/02_final_analysis.R` combines them automatically. The source-building logic is documented in `R/01_build_league_data.R`.

## Rodney Fort sports business data

Used for historical NBA attendance and archived team finance and franchise-value data.

- Website: https://sites.google.com/site/rodswebpages/codes

Attendance was combined with Basketball-Reference performance data for the league analysis. Archived Forbes financial and valuation data from Fort's collection were used for the Clippers figures.

## U.S. Bureau of Labor Statistics

CPI-U values were used to convert financial figures to 2017 dollars.

- Historical CPI table: https://www.bls.gov/regions/mid-atlantic/data/consumerpriceindexhistorical_us_table.htm

The inflation-adjusted values used in the figures are included in the cleaned financial CSVs.

## U.S. Census Bureau

Used in the written report for the 2015 Los Angeles-Long Beach-Anaheim metropolitan population statistic.

- Source table: https://www.census.gov/content/dam/Census/newsroom/releases/2016/cb16-cn43_table_6.pdf

## Reproducibility

The cleaned data committed to this repository are sufficient to reproduce the final regressions, robustness check, fitted-attendance analysis, and figures with `source("R/run_all.R")`.

The original downloaded source files are not committed. Their source locations are listed above. `R/01_build_league_data.R` records the construction logic and can be used if the original Basketball-Reference and Fort downloads are placed in the expected `data/raw/` locations.
