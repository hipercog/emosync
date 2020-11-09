#define function that removes NA before calculating the cosine similarity
library(lsa)
cos.na <- function(x,y)
{
  cosmat <- cosine(na.omit(cbind(x,y)))
  return(cosmat[2, 1])
}

#method 1

sync_2feats_1emo <- function(dat, emotion, feature1, feature2, TIMECOR = TRUE) {
  
  feats <- tryCatch({
    # handle case where feature params are passed as strings, i.e. dataframe variable names
    if (class(feature1) == "character"){
      list(as.name(feature1), as.name(feature2))
    }
  }, error = function(e){
    # handle case where feature params are passed as symbols, i.e. variables in dataframe
    return(list(enquo(feature1), enquo(feature2)))
  })

  feat1 <- feats[[1]]
  feat2 <- feats[[2]]
    
  dat2 <- dat %>% subset(event==emotion) %>%
    group_by(ID, trial) %>%
    mutate(feature1_name = cor(ts, !!feat1, method="kendall", use="pairwise"), #note: use ":=" instead of "=" if dynamic name is needed
           feature2_name = cor(ts, !!feat2, method="kendall", use="pairwise")) %>%
    ungroup() %>%
    dplyr::select(ID, ts, trial, feature1_name, feature2_name) %>%
    pivot_wider(names_from = ts, values_from = ts) %>%
    group_by(ID) %>%
    mutate(cosine_similarity = cos.na(feature1_name, feature2_name)) %>%
    ungroup() %>%
    select(-(5:9))
  if (TIMECOR){
    names(dat2)[names(dat2) == "feature1_name"] <- paste0("kendall_", deparse(substitute(feat1)))
    names(dat2)[names(dat2) == "feature2_name"] <- paste0("kendall_", deparse(substitute(feat2)))
  }else{
    dat2 <- dat2 %>%
      dplyr::select(ID, trial, cosine_similarity) %>%
      pivot_wider(names_from = trial, values_from = trial) %>%
      select(1:2)
  }
  names(dat2)[names(dat2) == "cosine_similarity"] <- paste0("cos.sim_", deparse(substitute(feat1)), "_", deparse(substitute(feat2)))
  dat2 <- mutate(dat2, emotion=rep(emotion, n()))
  
  return(dat2)
}


#method 2
sync_featvec_2emos <- function(dat, emotion1, emotion2, featurelist) {
  
  if (emotion1 %in% dat$event){
    dat$var <- dat$event
  } else if (emotion1 %in% dat$motivation){
    dat$var <- dat$motivation
  } else if (emotion1 %in% dat$valence){
    dat$var <- dat$valence 
  }
  
  featurelist <- enquo(featurelist)
  dat <- dplyr::select(dat, c(ID, var, trial, ts, !!featurelist)) %>%
    na.exclude()
  
  dat$timeslice <- dat$ts
  
  datemo1 <- dat %>% subset(var==emotion1) %>%
    group_by(ID, timeslice) %>%
    summarise_at(vars(!!featurelist), mean) %>%
    ungroup() %>%
    group_by(ID) %>%
    summarise_at(vars(!!featurelist), list(~cor(., y=timeslice, method="kendall", use="pairwise")))
  
  datemo2 <- dat %>% subset(var==emotion2) %>%
    group_by(ID, timeslice) %>%
    summarise_at(vars(!!featurelist), mean) %>%
    ungroup() %>%
    group_by(ID) %>%
    summarise_at(vars(!!featurelist), list(~cor(., y=timeslice, method="kendall", use="pairwise"))) 
  
  nsbj <- nrow(datemo1)
  cos_sim <- matrix(nsbj, 1)
  
  for (i in 1:nsbj) {
    vec1 <- datemo1[i, 2:ncol(datemo1)]
    vec2 <- datemo2[i, 2:ncol(datemo2)]
    cos_sim[i] <- cosine(unlist(vec1), unlist(vec2))
  }
  
  cos_sim <- as.data.frame(t(rbind(datemo1$ID, cos_sim)))
  
  return(cos_sim)
}