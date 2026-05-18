#!/usr/bin/env Rscript
# Petit script d'exemple : genere des donnees synthetiques, calcule des
# statistiques par groupe avec tidyverse, et ecrit le resultat en CSV.

suppressPackageStartupMessages(library(tidyverse))

args <- commandArgs(trailingOnly = TRUE)
output_path <- if (length(args) >= 1) args[[1]] else "/tmp/hello_tidyverse.csv"

set.seed(42)

df <- tibble(
  group = sample(c("A", "B", "C"), size = 300, replace = TRUE),
  value = rnorm(300, mean = 10, sd = 3)
)

summary_df <- df |>
  group_by(group) |>
  summarise(
    n        = n(),
    mean     = mean(value),
    sd       = sd(value),
    .groups  = "drop"
  ) |>
  arrange(group)

cat("=== Resume par groupe ===\n")
print(summary_df)

write_csv(summary_df, output_path)
cat(sprintf("[hello_tidyverse] CSV ecrit dans : %s\n", output_path))
