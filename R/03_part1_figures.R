# Recreate the main Clippers figures used in Part 1.
# These figures use the cleaned CSVs included in data/cleaned.

library(tidyverse)
library(ggplot2)
library(patchwork)
library(scales)

out_fig <- "output/figures"
dir.create(out_fig, recursive = TRUE, showWarnings = FALSE)

values <- read_csv(
  "data/cleaned/lakers_clippers_values_1999_2017.csv",
  show_col_types = FALSE
)

value_share <- values |>
  select(year, team, value) |>
  pivot_wider(names_from = team, values_from = value) |>
  mutate(clippers_share = 100 * Clippers / (Clippers + Lakers))

graph_value_share <- ggplot(value_share, aes(x = year, y = clippers_share)) +
  geom_vline(xintercept = 2012, linetype = "dashed", linewidth = 0.7, color = "grey55") +
  geom_line(linewidth = 1.1, color = "#A65F5F") +
  geom_point(size = 2.5, color = "#A65F5F") +
  scale_x_continuous(breaks = seq(1999, 2017, by = 2)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Clippers' Share of Los Angeles NBA Franchise Value",
    subtitle = "Clippers value as a percentage of combined Clippers and Lakers value, 1999–2017",
    x = "Year",
    y = "Clippers Share of Combined Franchise Value"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(out_fig, "clippers_share_la_value.png"), graph_value_share, width = 8, height = 5, dpi = 300)

perf <- read_csv("data/cleaned/clippers_performance_1999_2017.csv", show_col_types = FALSE)
dunks <- read_csv("data/cleaned/clippers_dunks_1999_2017.csv", show_col_types = FALSE)
attendance <- read_csv("data/cleaned/clippers_attendance_1999_2017.csv", show_col_types = FALSE)

clippers_history <- perf |>
  left_join(dunks, by = "season") |>
  left_join(attendance, by = "season") |>
  mutate(
    games = wins + losses,
    dunks_pg = made_dunks / games,
    season_start = as.numeric(str_sub(season, 1, 4)),
    season_id = row_number()
  ) |>
  arrange(season_start) |>
  mutate(season_id = row_number())

lob_city_x <- clippers_history |>
  filter(season == "2011-12") |>
  pull(season_id)

theme_clippers <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_blank(),
    axis.title.y = element_text(face = "bold", size = 9, margin = margin(r = 12)),
    axis.title.x = element_text(face = "bold", size = 9, margin = margin(t = 10)),
    axis.text.y = element_text(size = 7.5, margin = margin(r = 3)),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7.5),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.margin = margin(5, 8, 5, 12)
  )

base_x <- scale_x_continuous(
  breaks = clippers_history$season_id,
  labels = clippers_history$season
)

g_attendance <- ggplot(clippers_history, aes(season_id, home_attendance_pg)) +
  geom_line(linewidth = 1, color = "#2A9D8F") +
  geom_point(size = 2.2, color = "#2A9D8F") +
  geom_vline(xintercept = lob_city_x, linetype = "dashed", color = "grey40") +
  base_x + scale_y_continuous(labels = comma) +
  labs(y = "Attendance\nper game", x = NULL) + theme_clippers +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

g_win <- ggplot(clippers_history, aes(season_id, win_pct)) +
  geom_line(linewidth = 1, color = "#264653") +
  geom_point(size = 2.2, color = "#264653") +
  geom_vline(xintercept = lob_city_x, linetype = "dashed", color = "grey40") +
  base_x + scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(y = "Winning\npercentage", x = NULL) + theme_clippers +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

g_dunk <- ggplot(clippers_history, aes(season_id, dunks_pg)) +
  geom_line(linewidth = 1, color = "#7A5C8E") +
  geom_point(size = 2.2, color = "#7A5C8E") +
  geom_vline(xintercept = lob_city_x, linetype = "dashed", color = "grey40") +
  base_x + labs(y = "Dunks\nper game", x = NULL) + theme_clippers +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

g_pace <- ggplot(clippers_history, aes(season_id, pace)) +
  geom_line(linewidth = 1, color = "#A65F5F") +
  geom_point(size = 2.2, color = "#A65F5F") +
  geom_vline(xintercept = lob_city_x, linetype = "dashed", color = "grey40") +
  base_x + labs(y = "Pace", x = "Season") + theme_clippers

clippers_four_panel <- (g_attendance / g_win / g_dunk / g_pace) +
  plot_layout(heights = c(1, 1, 1, 1)) +
  plot_annotation(
    title = "Los Angeles Clippers: Attendance, Winning, Dunk Frequency and Pace",
    subtitle = "1999–00 to 2016–17",
    theme = theme(
      plot.title = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(size = 10)
    )
  )

ggsave(
  file.path(out_fig, "clippers_historical_stacked_graph.png"),
  clippers_four_panel,
  width = 9, height = 7.8, dpi = 300
)

finance <- read_csv(
  "data/cleaned/clippers_finance_2010_2017.csv",
  show_col_types = FALSE
)

graph_gate_revenue <- ggplot(finance, aes(x = season, y = real_gate_revenue, group = 1)) +
  geom_line(linewidth = 1.1, color = "#7A5C8E") +
  geom_point(size = 2.7, color = "#7A5C8E") +
  labs(
    title = "Los Angeles Clippers Gate Revenue",
    subtitle = "2009–10 to 2016–17",
    x = "Season",
    y = "Gate Revenue ($ millions, 2017 dollars)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold")
  )

ggsave(file.path(out_fig, "clippers_gate_revenue.png"), graph_gate_revenue, width = 7, height = 5, dpi = 300)
