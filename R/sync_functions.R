corr_rollmed_1pr <- function(df, a, b, corvar, wnd, stp)
{
  require(RcppRoll)
  dfa <- filter(df, Part == a & ab == 1) %>% select(corvar)
  dfb <- filter(df, Part == b & ab == 2) %>% select(corvar)
  dfa.roll <- roll_median(as.numeric(unlist(dfa)), n=wnd, by=stp)
  dfb.roll <- roll_median(as.numeric(unlist(dfb)), n=wnd, by=stp)
  if (length(dfa.roll) != length(dfb.roll)){
    print('A and B have different quantities of data!')
    return(NA)
  }
  retval <- list("corr" = cor(dfa.roll, dfb.roll), "count" = length(dfa.roll))
  return(retval)
}

corr_rollmed_allpr <- function(df, corvar, wnd, stp){
  
  sbjs <- unique(df$Part)
  match.pairs <- vector("numeric", length(sbjs))
  counts <- vector("numeric", length(sbjs))
  for (i in seq(1, length(sbjs))) {
    tmp <- corr_rollmed_1pr(df, sbjs[i], sbjs[i], corvar, wnd, stp)
    match.pairs[i] <- tmp$corr
    counts[i] <- tmp$count
  }
  if (all(diff(counts) == 0)) {
    counts <- counts[1]
  }else{
    print("Some pairs had different data quantities: is this right?")
    counts <- mean(counts)
  }
  return(list("corr" = match.pairs, "count" = counts))
}

upper2lower <- function(m) {
  m[lower.tri(m)] <- t(m)[lower.tri(m)]
  m
}

corr_rollmed_mat <- function(df, corvar, wnd, stp, triangle = TRUE){
  
  sbjs <- unique(df$Part)
  mat.pairs <- matrix(nrow = length(sbjs), ncol = length(sbjs))
  counts <- vector("numeric", length(sbjs))
  for (a in seq(1, length(sbjs))) {
    for (b in seq(a, length(sbjs))) {
      tmp <- corr_rollmed_1pr(df, sbjs[a], sbjs[b], corvar, wnd, stp)
      mat.pairs[a, b] <- tmp$corr
    }
    counts[a] <- tmp$count
  }
  if (!triangle) {
    # Copy upper triangle to lower
    mat.pairs <- upper2lower(mat.pairs)
  }
  if (all(diff(counts) == 0)) {
    counts <- counts[1]
  }else{
    print("Some pairs had different data quantities: is this right?")
    counts <- mean(counts)
  }
  return(list("corr" = mat.pairs, "count" = counts))
}

sample_matrix <- function(idx, mtrx, repl = FALSE) {
  sampix <- sample(idx, length(idx), repl)
  sampmat <- mtrx[, sampix]
  return(list("sampmat" = sampmat, "sampdiag" = diag(sampmat)))
}

sampmat_diag_stat <- function(FUN, idx, mtrx, repl = FALSE, ...) {
  samp <- sample_matrix(idx, mtrx, repl)
  
  sampstat <- FUN(samp$sampdiag, ...)
  
  return(sampstat)
}
