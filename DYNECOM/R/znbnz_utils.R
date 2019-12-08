# VISUALISATIONS
plot_rwb_cormat <- function(mtrx)
{
  ggplot(data = melt(mtrx), aes(x=Var1, y=Var2, fill=value)) + 
    geom_tile(color = "white") +
    scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                         midpoint = 0, limit = c(-1,1), space = "Lab", 
                         name="Pearson\nCorrelation") +
    theme_minimal() + 
    theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 12, hjust = 1))+
    coord_fixed()
  # + xlab("") + ylab("")
}


# READ and PARSE EDA data
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
