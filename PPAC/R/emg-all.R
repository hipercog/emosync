library(tidyverse)
library(R.matlab)
library(here)

source(file.path(here(), 'R', 'znbnz_utils.R'))

# Path to the data folder containing trials data in csv-format.
datapath <- file.path(str_replace(here(), 'emosync', 'project_PPAC'), 'EMG')

all_files <- list.files(datapath, all.files = T, pattern ="\\.csv$")

emg_all <- data.frame(matrix(ncol=7, nrow=0))
colnames(emg_all) <- c("zyg", "orb", "cor", "emo", "trial", "ts", "ID")

  # tunteet <- c("VIHA", "RENTOUTUNEISUUS", "SURU", "INNOSTUNEISUUS", "VOITTO", "ILO", "PELKO", "EMPATIA", "INHO")
  # emo <- c("ANGER", "RELAXATION", "DEPRESSION", "ENTHUSIASM", "TRIUMPH", "JOY", "FEAR", "EMPATHY", "DISGUST")
tunteet <- c("VIHA_rsp", "RENTOUTUNEISUUS_rsp", "SURU_rsp", "INNOSTUNEISUUS_rsp", 
             "VOITTO_rsp", "ILO_rsp", "PELKO_rsp", "EMPATIA_rsp", "INHO_rsp")
emo <- c("ANGER_rsp", "RELAXATION_rsp", "DEPRESSION_rsp", "ENTHUSIASM_rsp", 
         "TRIUMPH_rsp", "JOY_rsp", "FEAR_rsp", "EMPATHY_rsp", "DISGUST_rsp")

for (j in 1:length(all_files)) {
  sXemg <- read.csv(file.path(datapath, all_files[j]))
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
    emg$emo <- str_replace(tolower(emo[k]), "_rsp", "")
    emg$trial <- rep(1, nrow(emg))
    emg$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
    for (i in 2:length(idx)){
      tmp = sXemg[seq(idx[i], idx[i]+49), -1]
      tmp$emo <- str_replace(tolower(emo[k]), "_rsp", "")
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
rename("event"= emo, "ts" = sec) 
emgavg$ID <- as.factor(emgavg$ID)
emgavg$event <- as.factor(emgavg$event)
emgavg$trial <- as.factor(emgavg$trial)
emgavg$ts <- as.factor(emgavg$ts)

rm(all_files, tmp, sXemg, emg, i, idx, j, k)
