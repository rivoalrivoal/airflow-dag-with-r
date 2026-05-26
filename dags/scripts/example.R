#!/usr/bin/env Rscript
# Pipeline : telecharge file.csv depuis S3 (MinIO), ajoute une colonne total,
# uploade result_YYYYMMDD_HHMM.csv (heure de Paris) dans le meme bucket.

needed <- c("readr", "dplyr", "paws.storage")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(paws.storage)
})

env_req <- function(name) {
  v <- Sys.getenv(name, unset = NA)
  if (is.na(v) || !nzchar(v)) stop(sprintf("Variable d'environnement manquante : %s", name))
  v
}

access_key   <- env_req("AWS_ACCESS_KEY_ID")
secret_key   <- env_req("AWS_SECRET_ACCESS_KEY")
endpoint_url <- env_req("S3_ENDPOINT_URL")
bucket       <- env_req("S3_BUCKET")

s3 <- paws.storage::s3(
  config = list(
    credentials = list(creds = list(
      access_key_id     = access_key,
      secret_access_key = secret_key
    )),
    endpoint            = endpoint_url,
    region              = "us-east-1",
    s3_force_path_style = TRUE
  )
)

tmp_in <- tempfile(fileext = ".csv")
resp <- s3$get_object(Bucket = bucket, Key = "file.csv")
writeBin(resp$Body, tmp_in)

df <- read_csv2(tmp_in, show_col_types = FALSE)
df <- df |> mutate(total = col1 + col2)

tmp_out <- tempfile(fileext = ".csv")
write_csv2(df, tmp_out)

ts <- format(Sys.time(), "%Y%m%d_%H%M", tz = "Europe/Paris")
key_out <- paste0("result_", ts, ".csv")

body <- readBin(tmp_out, what = "raw", n = file.info(tmp_out)$size)
s3$put_object(Bucket = bucket, Key = key_out, Body = body)

cat(sprintf("[r-s3] %d lignes traitees -> s3://%s/%s\n", nrow(df), bucket, key_out))