# Final league models and Clippers fitted-attendance analysis

library(tidyverse)
library(broom)
library(grid)
library(gridExtra)
library(gtable)

out_fig <- "output/figures"
out_tab <- "output/tables"
dir.create(out_fig, recursive = TRUE, showWarnings = FALSE)
dir.create(out_tab, recursive = TRUE, showWarnings = FALSE)

part2_data <- read_csv(
  "data/cleaned/nba_1999_2017.csv",
  show_col_types = FALSE
) |>
  mutate(season = factor(season, levels = unique(season)))

reg1 <- lm(home_attendance_pg ~ win_pct, data = part2_data)
reg2 <- lm(home_attendance_pg ~ win_pct + dunks_pg + pace, data = part2_data)
reg3 <- lm(
  home_attendance_pg ~ win_pct + dunks_pg + pace + factor(season),
  data = part2_data
)

reg3_30team <- lm(
  home_attendance_pg ~ win_pct + dunks_pg + pace + factor(season),
  data = part2_data |> filter(as.character(season) >= "2004-05")
)

cat("\nMODEL 1\n"); print(summary(reg1))
cat("\nMODEL 2\n"); print(summary(reg2))
cat("\nMODEL 3\n"); print(summary(reg3))
cat("\n30-TEAM ROBUSTNESS\n"); print(summary(reg3_30team))

get_coef <- function(model, variable) {
  result <- tidy(model) |> filter(term == variable)
  if (nrow(result) == 0) return("")
  stars <- case_when(
    result$p.value < 0.001 ~ "***",
    result$p.value < 0.01 ~ "**",
    result$p.value < 0.05 ~ "*",
    TRUE ~ ""
  )
  paste0(round(result$estimate, 2), stars)
}

get_se <- function(model, variable) {
  result <- tidy(model) |> filter(term == variable)
  if (nrow(result) == 0) return("")
  paste0("(", round(result$std.error, 2), ")")
}

g1 <- glance(reg1); g2 <- glance(reg2); g3 <- glance(reg3)

regression_table <- tibble(
  Variable = c(
    "Winning Percentage", "", "Dunks Per Game", "", "Pace", "",
    "Season Controls", "Observations", "R²", "Adjusted R²"
  ),
  `Model 1` = c(
    get_coef(reg1, "win_pct"), get_se(reg1, "win_pct"), "", "", "", "",
    "No", nobs(reg1), sprintf("%.3f", g1$r.squared), sprintf("%.3f", g1$adj.r.squared)
  ),
  `Model 2` = c(
    get_coef(reg2, "win_pct"), get_se(reg2, "win_pct"),
    get_coef(reg2, "dunks_pg"), get_se(reg2, "dunks_pg"),
    get_coef(reg2, "pace"), get_se(reg2, "pace"),
    "No", nobs(reg2), sprintf("%.3f", g2$r.squared), sprintf("%.3f", g2$adj.r.squared)
  ),
  `Model 3` = c(
    get_coef(reg3, "win_pct"), get_se(reg3, "win_pct"),
    get_coef(reg3, "dunks_pg"), get_se(reg3, "dunks_pg"),
    get_coef(reg3, "pace"), get_se(reg3, "pace"),
    "Yes", nobs(reg3), sprintf("%.3f", g3$r.squared), sprintf("%.3f", g3$adj.r.squared)
  )
)

row_fills <- rep(c("#F7F7F7", "#F7F7F7", "white", "white"), length.out = nrow(regression_table))

table_theme <- ttheme_minimal(
  base_size = 9,
  core = list(
    fg_params = list(hjust = 0.5, x = 0.5, fontsize = 8.5),
    bg_params = list(fill = row_fills, col = NA)
  ),
  colhead = list(
    fg_params = list(col = "white", fontface = "bold", fontsize = 9.5),
    bg_params = list(fill = "#2F3E46", col = NA)
  )
)

reg_table <- tableGrob(regression_table, rows = NULL, theme = table_theme)
reg_table$widths <- unit(c(2.7, 1.55, 1.55, 1.55), "in")

sig_note <- textGrob(
  "* p < 0.05,  ** p < 0.01,  *** p < 0.001",
  x = 0, hjust = 0,
  gp = gpar(fontsize = 7.5, fontface = "italic")
)

final_reg_table <- gtable_add_rows(reg_table, heights = unit(6, "pt"), pos = nrow(reg_table))
final_reg_table <- gtable_add_rows(
  final_reg_table,
  heights = grobHeight(sig_note) + unit(6, "pt"),
  pos = nrow(final_reg_table)
)
final_reg_table <- gtable_add_grob(
  final_reg_table, sig_note,
  t = nrow(final_reg_table), l = 1, r = ncol(final_reg_table)
)

png(file.path(out_tab, "part2_regression_results.png"), width = 1600, height = 820, res = 200)
grid.newpage(); grid.draw(final_reg_table)
dev.off()

hypothesis_table <- data.frame(
  Variable = c("Winning~Percentage", "Dunks~Per~Game", "Pace"),
  `Null Hypothesis` = c(
    'H[0]~":"~beta[1] == 0', 'H[0]~":"~beta[2] == 0', 'H[0]~":"~beta[3] == 0'
  ),
  `Alternative Hypothesis` = c(
    'H[1]~":"~beta[1] != 0', 'H[1]~":"~beta[2] != 0', 'H[1]~":"~beta[3] != 0'
  ),
  check.names = FALSE
)

hyp_theme <- ttheme_minimal(
  base_size = 10,
  core = list(
    fg_params = list(fontsize = 9, hjust = 0.5, x = 0.5, parse = TRUE),
    bg_params = list(fill = c("#F7F7F7", "white", "#F7F7F7"), col = NA)
  ),
  colhead = list(
    fg_params = list(col = "white", fontface = "bold", fontsize = 9.5),
    bg_params = list(fill = "#2F3E46", col = NA)
  )
)

hyp_table <- tableGrob(hypothesis_table, rows = NULL, theme = hyp_theme)
png(file.path(out_tab, "hypothesis_table.png"), width = 1400, height = 420, res = 200)
grid.newpage(); grid.draw(hyp_table)
dev.off()

clippers_actual_fit <- part2_data |>
  filter(team == "Los Angeles Clippers") |>
  select(team, season, home_attendance_pg, win_pct, dunks_pg, pace) |>
  arrange(season)

clippers_actual_fit$fitted_attendance <- predict(reg3, newdata = clippers_actual_fit)
clippers_actual_fit$residual <- clippers_actual_fit$home_attendance_pg - clippers_actual_fit$fitted_attendance

lob_city <- clippers_actual_fit |>
  filter(as.character(season) %in% c(
    "2011-12", "2012-13", "2013-14", "2014-15", "2015-16", "2016-17"
  ))

lob_city_gap <- lob_city |>
  summarise(
    avg_actual = mean(home_attendance_pg, na.rm = TRUE),
    avg_fitted = mean(fitted_attendance, na.rm = TRUE),
    avg_gap = mean(residual, na.rm = TRUE)
  )

write_csv(lob_city_gap, file.path(out_tab, "lob_city_fitted_gap.csv"))
print(lob_city_gap)

graph_actual_vs_fitted <- ggplot(clippers_actual_fit, aes(x = season, group = 1)) +
  geom_line(aes(y = home_attendance_pg, color = "Actual Attendance"), linewidth = 0.85) +
  geom_line(aes(y = fitted_attendance, color = "Fitted Attendance"), linewidth = 0.85) +
  scale_color_manual(values = c(
    "Actual Attendance" = "#A65F5F",
    "Fitted Attendance" = "#6E6E6E"
  )) +
  labs(
    title = "Los Angeles Clippers: Actual vs Fitted Attendance",
    subtitle = "1999–00 to 2016–17",
    x = "Season",
    y = "Average Home Attendance per Game",
    color = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size = 8),
    axis.title.x = element_text(face = "bold", size = 9, margin = margin(t = 12)),
    axis.title.y = element_text(face = "bold", size = 9, margin = margin(r = 14)),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.margin = margin(t = 10, r = 15, b = 10, l = 15)
  )

ggsave(
  file.path(out_fig, "clippers_actual_vs_fitted_model3.png"),
  graph_actual_vs_fitted,
  width = 10, height = 6, dpi = 300
)
