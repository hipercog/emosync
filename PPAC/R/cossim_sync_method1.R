library(tidyr)
library(tidyverse)
library(lmerTest)
library(lme4)
library(MuMIn)
library(lattice)
library(lsa)
library(here)

source(file.path(here(), 'R', 'cossim_sync_method_functions.R'))

polku <- file.path(here(), 'data', 'ppac_all.csv')
PPAC <- read.csv(polku, header = T, sep = ",")

sync_2feats_1emo(PPAC, "anger", orb_avg, fasym_rel, TIMECOR = F)

###
# fnames <- subset somehow
featnames <- colnames(select(PPAC, 5:17))
fnames <- featnames[c(1, 5, 6, 7, 8, 9)]
flen <- length(fnames)
emotions <- unique(PPAC$event)
emosync <- NULL

for (e in emotions){
  allsync <- sync_2feats_1emo(PPAC, e, fnames[1], fnames[2], FALSE)
  
  for (i in 2:flen - 1) {
    for (j in (i+1) : flen) {
      tmp <- sync_2feats_1emo(PPAC, e, fnames[i], fnames[j], FALSE)
      allsync <- merge(allsync, tmp, sort = F)
    }
  }
  emosync <- rbind(emosync, allsync)
  rm(tmp, allsync)
  
}

emosyncL <- emosync %>%
  pivot_longer(cols = starts_with("cos.sim_"), names_to = "feat.pair", values_to = "cos.sim") %>%
  mutate(feat.pair = gsub("cos.sim_", "", feat.pair))

# average ID x emotion across all feat pairs
mean.cos.sim <- emosyncL %>% 
  group_by(ID, emotion) %>% 
  summarise(sync = mean(abs(na.omit(cos.sim))))

# average each emotion across all feat pairs
mean.emo <- emosyncL %>% 
  group_by(emotion) %>% 
  summarise(sync = mean(na.omit(cos.sim)))

# average each feat pair across all ID x emotion
mean.feat.pair <- emosyncL %>% 
  group_by(feat.pair) %>% 
  summarise(sync = mean(na.omit(cos.sim)))

# filter to Zyg x Orb and average across all ID
mean.emo.zyg.orb <- emosyncL %>% 
  filter(feat.pair == "zyg_avg_orb_avg") %>%
  group_by(emotion) %>%
  summarise(zyg.orb.sync = mean(na.omit(cos.sim)))

# filter to Zyg x Orb and average across all emotions
mean.id.zyg.orb <- emosyncL %>% 
  filter(feat.pair == "zyg_avg_orb_avg") %>%
  group_by(ID) %>%
  summarise(zyg.orb.sync = mean(na.omit(cos.sim)))

# filter to Anger and average across all ID x emotion
mean.feat.pair.anger <- emosyncL %>% 
  filter(emotion == "anger") %>%
  group_by(feat.pair) %>%
  summarise(sync = mean(na.omit(cos.sim)))

df <- merge(test5, perf)

summary(lm(visAcc ~ zyg.orb.sync, data = df))
