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
tiedosto <- read.csv(polku, header = T, sep = ",")

sync_2feats_1emo(tiedosto, "anger", orb_avg, fasym_rel, TIMECOR = FALSE)

###
fnames <- colnames(select(tiedosto, 5:17))
flen <- length(fnames)
emotions <- unique(tiedosto$event)
emosync <- NULL

for (e in emotions){
  allsync <- sync_2feats_1emo(tiedosto, e, fnames[1], fnames[2], FALSE)
  
  for (i in 2:flen - 1) {
    for (j in (i+1) : flen) {
      tmp <- sync_2feats_1emo(tiedosto, e, fnames[i], fnames[j], FALSE)
      allsync <- merge(allsync, tmp)
    }
  }
  emosync <- rbind(emosync, allsync)
  rm(tmp, allsync)
  
}

emosyncL <- emosync %>%
  pivot_longer(cols = starts_with("cos_sim."), names_to = "feat.pair", values_to = "cos_sim") %>%
  mutate(feat.pair = gsub("cos_sim.", "", feat.pair))
