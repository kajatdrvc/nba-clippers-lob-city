# Build NBA team-season dataset, 1999-00 through 2016-17
# Sources:
#   - Basketball-Reference / Sports Reference: wins, losses, pace, made dunks
#   - Rodney Fort sports business data: home attendance
#
# This script documents the source-data construction. The external source downloads
# are not committed to this repository; see DATA_SOURCES.md for source locations.

library(tidyverse)
library(rvest)

raw_dir <- "data/raw"
bref_dir <- file.path(raw_dir, "basketball_reference")
clean_dir <- "data/cleaned"
dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

old_seasons <- c(
  "1999-00", "2000-01", "2001-02", "2002-03", "2003-04",
  "2004-05", "2005-06", "2006-07", "2007-08", "2008-09"
)

old_advanced_files <- tibble(
  season = old_seasons,
  file = c(
    "sportsref_download (10).xls", "sportsref_download (11).xls",
    "sportsref_download (12).xls", "sportsref_download (13).xls",
    "sportsref_download (14).xls", "sportsref_download (16).xls",
    "sportsref_download (17).xls", "sportsref_download (18).xls",
    "sportsref_download (19).xls", "sportsref_download (20).xls"
  )
) |>
  mutate(path = file.path(raw_dir, file))

old_shooting_files <- tibble(
  season = old_seasons,
  file = c(
    "sportsref_download.xls", "sportsref_download (1).xls",
    "sportsref_download (2).xls", "sportsref_download (3).xls",
    "sportsref_download (4).xls", "sportsref_download (5).xls",
    "sportsref_download (6).xls", "sportsref_download (7).xls",
    "sportsref_download (8).xls", "sportsref_download (9).xls"
  )
) |>
  mutate(path = file.path(raw_dir, file))

recent_years <- 2010:2017
recent_seasons <- c(
  "2009-10", "2010-11", "2011-12", "2012-13",
  "2013-14", "2014-15", "2015-16", "2016-17"
)

recent_advanced_files <- tibble(
  season = recent_seasons,
  file = paste0("bref_advanced_", recent_years, ".xls")
) |>
  mutate(path = file.path(bref_dir, file))

recent_shooting_files <- tibble(
  season = recent_seasons,
  file = paste0("bref_shooting_", recent_years, ".xls")
) |>
  mutate(path = file.path(bref_dir, file))

advanced_files <- bind_rows(old_advanced_files, recent_advanced_files)
shooting_files <- bind_rows(old_shooting_files, recent_shooting_files)

stopifnot(all(file.exists(advanced_files$path)))
stopifnot(all(file.exists(shooting_files$path)))

read_advanced_table <- function(path, season) {
  rows <- read_html(path) |> html_elements("tbody tr")

  tibble(
    team = rows |> html_element('[data-stat="team"]') |> html_text2(),
    wins = rows |> html_element('[data-stat="wins"]') |> html_text2() |> as.numeric(),
    losses = rows |> html_element('[data-stat="losses"]') |> html_text2() |> as.numeric(),
    pace = rows |> html_element('[data-stat="pace"]') |> html_text2() |> as.numeric()
  ) |>
    mutate(
      season = season,
      team = team |> str_remove("\\*$") |> str_squish()
    ) |>
    filter(!is.na(team), team != "")
}

read_shooting_table <- function(path, season) {
  rows <- read_html(path) |> html_elements("tbody tr")

  tibble(
    team = rows |> html_element('[data-stat="team"]') |> html_text2(),
    shooting_games = rows |> html_element('[data-stat="g"]') |> html_text2() |> as.numeric(),
    made_dunks = rows |> html_element('[data-stat="fg_dunk"]') |> html_text2() |> as.numeric()
  ) |>
    mutate(
      season = season,
      team = team |> str_remove("\\*$") |> str_squish()
    ) |>
    filter(!is.na(team), team != "")
}

nba_performance <- map2_dfr(advanced_files$path, advanced_files$season, read_advanced_table)
nba_dunks <- map2_dfr(shooting_files$path, shooting_files$season, read_shooting_table)

nba_history <- nba_performance |>
  left_join(nba_dunks, by = c("team", "season")) |>
  mutate(
    games = wins + losses,
    win_pct = wins / games,
    dunks_pg = made_dunks / games
  )

attendance_raw <- read_csv(
  file.path(raw_dir, "nba_attendance.csv"),
  skip = 5,
  show_col_types = FALSE
)

analysis_seasons <- c(old_seasons, recent_seasons)

attendance_long <- attendance_raw |>
  select(Team, all_of(analysis_seasons)) |>
  pivot_longer(
    cols = all_of(analysis_seasons),
    names_to = "season",
    values_to = "home_attendance"
  ) |>
  mutate(home_attendance = parse_number(as.character(home_attendance))) |>
  rename(attendance_team = Team)

attendance_lookup <- tribble(
  ~team, ~attendance_team,
  "Atlanta Hawks", "ATLANTA HAWKS",
  "Boston Celtics", "BOSTON CELTICS",
  "Charlotte Hornets", "CHARLOTTE HORNETS-Bobcats",
  "Charlotte Bobcats", "CHARLOTTE HORNETS-Bobcats",
  "Chicago Bulls", "CHICAGO STAGS-PACKERS/ZEPHYRS-BULLS",
  "Cleveland Cavaliers", "CLEVELAND REBELS-CAVALIERS",
  "Dallas Mavericks", "DALLAS MAVERICKS",
  "Denver Nuggets", "DENVER NUGGETS",
  "Detroit Pistons", "DETROIT FALCONS-PISTONS",
  "Golden State Warriors", "GOLDEN STATE (OAKLAND) WARRIORS",
  "Houston Rockets", "HOUSTON ROCKETS",
  "Indiana Pacers", "INDIANAPOLIS OLYMPIANS-INDIANA PACERS",
  "Los Angeles Clippers", "LOS ANGELES CLIPPERS",
  "Los Angeles Lakers", "LOS ANGELES LAKERS",
  "Memphis Grizzlies", "MEMPHIS GRIZZLIES",
  "Miami Heat", "MIAMI HEAT",
  "Milwaukee Bucks", "MILWAUKEE HAWKS-BUCKS",
  "Minnesota Timberwolves", "MINNESOTA TIMBERWOLVES",
  "New Jersey Nets", "NEW JERSEY (NEW YORK) NETS",
  "Brooklyn Nets", "BROOLYN NETS",
  "New Orleans Hornets", "NEW ORLEANS Pelicans- JAZZ-Hornets",
  "New Orleans Pelicans", "NEW ORLEANS Pelicans- JAZZ-Hornets",
  "New Orleans/Oklahoma City Hornets", "Oklahoma City Jazz-Thunder",
  "New York Knicks", "NEW YORK KNICKERBOCKERS",
  "Oklahoma City Thunder", "Oklahoma City Jazz-Thunder",
  "Orlando Magic", "ORLANDO MAGIC",
  "Philadelphia 76ers", "PHILADELPHIA WARRIORS-76ERS",
  "Phoenix Suns", "PHOENIX SUNS",
  "Portland Trail Blazers", "PORTLAND TRAILBLAZERS",
  "Sacramento Kings", "SACRAMENTO KINGS",
  "San Antonio Spurs", "SAN ANTONIO SPURS",
  "Seattle SuperSonics", "SEATTLE SUPERSONICS",
  "Toronto Raptors", "TORONTO RAPTORS",
  "Utah Jazz", "UTAH JAZZ",
  "Vancouver Grizzlies", "VANCOUVER GRIZZLIES",
  "Washington Wizards", "WASHINGTON CAPITALS- BULLETS/WIZARDS"
)

nba_history <- nba_history |>
  left_join(attendance_lookup, by = "team") |>
  left_join(attendance_long, by = c("attendance_team", "season")) |>
  mutate(
    home_games = games / 2,
    home_attendance_pg = home_attendance / home_games
  ) |>
  select(
    team, season, wins, losses, games, win_pct, pace,
    made_dunks, dunks_pg, home_attendance, home_attendance_pg
  ) |>
  arrange(season, team)

stopifnot(nrow(nba_history) == 535)
stopifnot(sum(is.na(nba_history$win_pct)) == 0)
stopifnot(sum(is.na(nba_history$dunks_pg)) == 0)

write_csv(nba_history, file.path(clean_dir, "nba_1999_2017.csv"))
message("Wrote data/cleaned/nba_1999_2017.csv with ", nrow(nba_history), " rows.")
