packages <- c(
  "tidyverse",
  "rvest",
  "broom",
  "gridExtra",
  "gtable",
  "patchwork",
  "scales",
  "readxl"
)

new_packages <- packages[!packages %in% rownames(installed.packages())]
if (length(new_packages) > 0) install.packages(new_packages)
