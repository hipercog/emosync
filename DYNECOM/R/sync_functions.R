corr_mat <- function(df, corvar, triangle = TRUE, meth = "pearson")
{
  sbjs <- unique(df$Part)
  mat.pairs <- matrix(nrow = length(sbjs), ncol = length(sbjs))
  counts <- vector("numeric", length(sbjs))
  
  for (a in seq(1, length(sbjs))) {
    for (b in seq(a, length(sbjs))) {
      dfa <- filter(df, Part == sbjs[a] & ab == 1) %>% select(corvar) %>% unlist() %>% as.numeric
      dfb <- filter(df, Part == sbjs[b] & ab == 2) %>% select(corvar) %>% unlist() %>% as.numeric
      
      if (length(dfa) != length(dfb)){
        print(paste0('cor_mat::A', a, ' and B', b, ' have different quantities of data!'))
        return(NA)
      }
      mat.pairs[a, b] <- cor(dfa, dfb, method = meth)
    }
    counts[a] <- length(dfa)
  }
  if (!triangle) {
    # Copy upper triangle to lower
    mat.pairs <- upper2lower(mat.pairs)
  }
  if (all(diff(counts) == 0)) {
    counts <- counts[1]
  }else{
    print("corr_mat::Some pairs had different data quantities: is this right?")
    counts <- mean(counts)
  }
  return(list("corr" = mat.pairs, "count" = counts))
}


corr_rollme_1pr <- function(df, a, b, corvar, wnd, stp, method = "median", CTR = FALSE, SCL = FALSE)
{
  require(RcppRoll)
  func <- paste0("roll_", method)

  dfa <- filter(df, Part == a & ab == 1) %>% select(corvar) %>% unlist %>% as.numeric %>% scale(CTR, SCL) %>% drop
  dfb <- filter(df, Part == b & ab == 2) %>% select(corvar) %>% unlist %>% as.numeric %>% scale(CTR, SCL) %>% drop
  # 
  # dfa <- scale(dfa, CTR, SCL) # should do nothing unless defaults are overridden
  # dfb <- scale(dfb, CTR, SCL) # should do nothing unless defaults are overridden
  
  dfa.roll <- do.call(func, list(dfa, n=wnd, by=stp))
  dfb.roll <- do.call(func, list(dfb, n=wnd, by=stp))

  if (length(dfa.roll) != length(dfb.roll)){
    print('corr_rollme_1pr::A and B have different quantities of data!')
    return(NA)
  }
  retval <- list("corr" = cor(dfa.roll, dfb.roll), "count" = length(dfa.roll))
  return(retval)
}


# TODO - USE '...' PARAMS
corr_rollme_allpr <- function(df, corvar, wnd, stp, method = "median", CTR = FALSE, SCL = FALSE)
{
  sbjs <- unique(df$Part)
  match.pairs <- vector("numeric", length(sbjs))
  counts <- vector("numeric", length(sbjs))
  for (i in seq(1, length(sbjs))) {
    tmp <- corr_rollme_1pr(df, sbjs[i], sbjs[i], corvar, wnd, stp, method, CTR, SCL)
    match.pairs[i] <- tmp$corr
    counts[i] <- tmp$count
  }
  if (all(diff(counts) == 0)) {
    counts <- counts[1]
  }else{
    print("corr_rollme_allpr::Some pairs had different data quantities: is this right?")
    counts <- mean(counts)
  }
  return(list("corr" = match.pairs, "count" = counts))
}


upper2lower <- function(m) 
{
  m[lower.tri(m)] <- t(m)[lower.tri(m)]
  m
}


# TODO - USE '...' PARAMS
corr_rollme_mat <- function(df, corvar, wnd, stp, method = "median", CTR = FALSE, SCL = FALSE, triangle = TRUE)
{
  sbjs <- unique(df$Part)
  mat.pairs <- matrix(nrow = length(sbjs), ncol = length(sbjs))
  counts <- vector("numeric", length(sbjs))
  for (a in seq(1, length(sbjs))) {
    for (b in seq(a, length(sbjs))) {
      tmp <- corr_rollme_1pr(df, sbjs[a], sbjs[b], corvar, wnd, stp, method, CTR, SCL)
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
    print("corr_rollme_mat::Some pairs had different data quantities: is this right?")
    counts <- mean(counts)
  }
  return(list("corr" = mat.pairs, "count" = counts))
}


sample_matrix <- function(mtrx, repl = FALSE) 
{
  idx <- seq(1, ncol(mtrx))
  if (all(is.na(mtrx[lower.tri(mtrx)])))
  {
    mtrx <- upper2lower(mtrx)
  }
  sampix <- sample(idx, length(idx), repl)
  sampmat <- mtrx[, sampix]
  return(list("sampmat" = sampmat, "sampdiag" = diag(sampmat)))
}


sampmat_diag_stat <- function(FUN, mtrx, repl = FALSE, ...) 
{
  samp <- sample_matrix(mtrx, repl)
  sampstat <- FUN(samp$sampdiag, ...)
  return(sampstat)
}


# read two conditions with possibly many subconditions and ensure matched-pair data is returned
intersect_read <- function(base, patts, SKP = 0)
{
  if (length(patts) > 1){
    p1 <- patts[1]
    p2 <- patts[2]
  }else{
    p1 <- p2 <- patts
  }
  if (length(base) > 1){
    b1 <- base[1]
    b2 <- base[2]
  }else{
    b1 <- b2 <- base
  }
  dfa <- read_all_recordings(b1, pat=p1, ext="csv", skip = SKP)
  dfb <- read_all_recordings(b2, pat=p2, ext="csv", skip = SKP)
  dfa$ab <- 1
  dfb$ab <- 2
  dfa <- filter(dfa, Part %in% unique(dfb$Part))
  dfb <- filter(dfb, Part %in% unique(dfa$Part))
  df <- rbind(dfa, dfb)
  
  return(df)
}


# TODO - USE '...' PARAMS
cond2rollcormat <- function(base, patts, feat, wndw, step, rollmeth = "median", triangle = FALSE, CTR = FALSE, SCL = FALSE) 
{
  df <- intersect_read(base, patts, 1)
  subjs <- unique(df$Part)
  cormat <- corr_rollme_mat(df, feat, wndw, step, rollmeth, triangle, CTR = centr, SCL = skale)
  corrs <- diag(cormat$corr)
  avg.cor <- mean(corrs)
  
  return(list("cormat" = cormat$corr, "corrs" = corrs, "avg.cor" = avg.cor, "subjs" = subjs))
}


cond2cormat <- function(base, patts, feat, cormeth, triangle = FALSE)
{
  df <- intersect_read(base, patts)
  subjs <- unique(df$Part)
  cormat <- corr_mat(df, feat, triangle, cormeth)
  corrs <- diag(cormat$corr)
  avg.cor <- mean(corrs)
  
  return(list("cormat" = cormat$corr, "corrs" = corrs, "avg.cor" = avg.cor, "subjs" = subjs))
  # return(list("cormat" = cormat$corr, "corrs" = corrs, "avg.cor" = avg.cor))
}
