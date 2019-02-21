library(readr)


parse_recording <- function(fname){
  fn <- parse_number(basename(fname))
  rec <- read.csv(fname, sep = "\t", header = TRUE)
  rec$Part <- rep(fn, nrow(rec))
  rec
}

read_all_recordings <- function(basepath, pat="", ext="") {
  file_list <- list.files(basepath, pattern = paste0(".*", pat, ".*", ext), full.names = TRUE)
  if (length(file_list) == 0){
    print('No files found!')
    return()
  }
  i = 1
  out <- parse_recording(file_list[[1]])
  out$File <- rep(i, nrow(out))
  for (f in file_list[-1]) {
    i = i + 1
    rec <- parse_recording(f)
    rec$File <- rep(i, nrow(rec))
    out <- rbind(out, rec)
  }
  out
}