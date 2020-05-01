library(tidyverse)
library(R.matlab)

source("/Users/niinapeltonen/Desktop/Gradu/gradu-ohjelmat/emosync/R/read_parse_data.R")

basepath <- '/Users/niinapeltonen/Desktop/Gradu/gradu-data/EMG_PROCESSING/'
setwd(basepath)

all_files <- list.files("/Users/niinapeltonen/Desktop/Gradu/gradu-data/EMG_PROCESSING", all.files = T, pattern ="\\.csv$")

emg_all <- data.frame(matrix(ncol=7, nrow=0))
colnames(emg_all) <- c("zyg", "orb", "cor", "emo", "trial", "ts", "ID")

tunteet <- c("VIHA", "RENTOUTUNEISUUS", "SURU", "INNOSTUNEISUUS", "VOITTO", "ILO", "PELKO", "EMPATIA", "INHO")
emo <- c("ANGER", "RELAXATION", "DEPRESSION", "ENTHUSIASM", "TRIUMPH", "JOY", "FEAR", "EMPATHY", "DISGUST")

for (j in 1:length(all_files)) {
  sXemg <- read.csv(paste0(basepath, all_files[j]))
  for (k in 1:length(emo)) {
    idx = which(sXemg$sampevs == emo[k], arr.ind=TRUE)  
    # if empty, check finnish
    if (length(idx) == 0) {
      idx = which(sXemg$sampevs == tunteet[k], arr.ind=TRUE)
    }
    #if some emotion doesn't exist, move to next one
    if (length(idx) == 0) {
      next
    }
    emg <- sXemg[seq(idx[1], idx[1]+49), -1]
    emg$emo <- tolower(emo[k])
    emg$trial <- rep(1, nrow(emg))
    emg$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
    for (i in 2:length(idx)){
      tmp = sXemg[seq(idx[i], idx[i]+49), -1]
      tmp$emo <- tolower(emo[k])
      tmp$trial = rep(i, nrow(tmp))
      tmp$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
      emg <- rbind(emg, tmp)
    }
    emg$ID <- round(parse_number(all_files[j]) / 100)
    emg_all <- rbind(emg_all, emg)
  }
}

emgavg <- emg_all %>%
group_by(ID, emo, trial, sec) %>%
summarise(zyg_avg = mean(zyg), orb_avg = mean(orb), crg_avg=mean(crg)) %>%
rename("event"= emo) %>% 
rename("ts" = sec) 

