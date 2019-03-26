library(readr)


parse_recording <- function(fname, delim = ",", skip_lines = 0){
  fn <- parse_number(basename(fname))
  rec <- read.csv(fname, sep = delim, header = TRUE, skip = skip_lines)
  rec$Part <- rep(fn, nrow(rec))
  rec
}

read_all_recordings <- function(basepath, pat="", ext="", delim = ",", skip = 0) {
  file_list <- list.files(basepath, pattern = paste0(".*", pat, ".*", ext), full.names = TRUE)
  if (length(file_list) == 0){
    print('No files found!')
    return()
  }
  i = 1
  out <- parse_recording(file_list[[1]], delim, skip)
  out$File <- rep(i, nrow(out))
  for (f in file_list[-1]) {
    i = i + 1
    rec <- parse_recording(f, delim, skip)
    rec$File <- rep(i, nrow(rec))
    out <- rbind(out, rec)
  }
  out
}