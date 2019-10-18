# MATRIX MANIPULATIONS 
# reorder cormat by corr coef to identify patterns in the matrix. hclust for hierarchical clustering order
reorder_cormat <- function(cormat){
  # Use correlation between variables as distance
  dd <- as.dist((1-cormat)/2)
  hc <- hclust(dd)
  cormat <-cormat[hc$order, hc$order]
}
get_upper_tri <- function(data2){
  total <- data2
  total[lower.tri(total)]<- NA
  return(total)
}

# VISUALISATIONS
require(corrgram)
corrMatrix <- function(..., title = "Correlation matrix")
{
  require(corrgram)
  x <- list(...)
  # assume data and names have been passed as name-value pairs
  df <- as.data.frame(x[seq(2,length(x),2)])
  colnames(df) <- x[seq(1,length(x),2)]
  
  corrgram(df, order = TRUE, 
           lower.panel = panel.ellipse,
           upper.panel = panel.conf, 
           text.panel = panel.txt,
           diag.panel = panel.minmax, 
           main = title,
           gap = 1)
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
