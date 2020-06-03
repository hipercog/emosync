synchrony_wrangler <- function(data, emotion, feature1, feature2) {
  feature1 <- enquo(feature1)
  feature2 <- enquo(feature2)
  data2 <- data %>% subset(event==emotion) %>%
    group_by(ID, trial) %>%
    mutate(feature1_name = cor(ts, !!feature1, method="kendall", use="pairwise"), #note: use ":=" instead of "=" if dynamic name is needed
           feature2_name = cor(ts, !!feature2, method="kendall", use="pairwise")) %>%
    ungroup() %>%
    dplyr::select(ID, ts, trial, feature1_name, feature2_name, orb_avg) %>%
    spread(ts, orb_avg) %>% #this is clunky! Essentially any variable can be used to spread the data frame wrt "ts", but then the resulting 5 columns need to be removed (done at the end)
    group_by(ID) %>%
    mutate(cosine_similarity = cosine(feature1_name, feature2_name)) %>%
    ungroup() %>%
    mutate(emotion=rep(emotion, n()))
  data2 <- data2[,-c(5:9)]
  names(data2)[names(data2) == "feature1_name"] <- paste0("kendall", deparse(substitute(feature1)))
  names(data2)[names(data2) == "feature2_name"] <- paste0("kendall", deparse(substitute(feature2)))
  names(data2)[names(data2) == "cosine_similarity"] <- paste0("cos_sim", deparse(substitute(feature1)), 
                                                              deparse(substitute(feature2)))
  return(data2)
}