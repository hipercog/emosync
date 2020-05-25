library(tidyverse)
library(R.matlab)
library(here)

source(file.path(here(), 'R', 'znbnz_utils.R'))

# Path to the data folder containing trials data in csv-format.
datapath <- file.path(str_replace(here(), 'emosync', 'project_PPAC'), 'EDA')

eda_all <- data.frame(matrix(ncol=7, nrow=0))
colnames(eda_all) <- c('1to3', '3to5', '5to7', '7to9', '9to11', 'emoeng', 'ID')

#EDA
times <- c('1to3', '3to5', '5to7', '7to9', '9to11')

typstr <- c('PPACv00105_autobio_era','PPACv00204_autobio_era','PPACv00304_autobio_era','PPACv00403_autobio_era',
            'PPACv00506_autobio_era','PPACv00602_autobio_era','PPACv00705_autobio_era','PPACv00803_autobio_era',
            'PPACv00902_autobio_era','PPACv01003_autobio_era','PPACv01103_autobio_era','PPACv01203_autobio_era',
            'PPACv01302_autobio_era','PPACv01505_autobio_era','PPACv01605_autobio_era','PPACv01702_autobio_era',
            'PPACv01802_autobio_era','PPACv01904_autobio_era','PPACv02004_autobio_era','PPACv02102_autobio_era',
            'PPACv02203_autobio_era','PPACv02303_autobio_era','PPACv02404_autobio_era','PPACv02604_autobio_era',
            'PPACv02702_autobio_era','PPACv02802_autobio_era','PPACv02904_autobio_era','PPACv03005_autobio_era',
            'PPACv03104_autobio_era','PPACv03205_autobio_era')
# tunteet <- c("VIHA", "RENTOUTUNEISUUS", "SURU", "INNOSTUNEISUUS", "VOITTO", "ILO", "PELKO", "EMPATIA", "INHO")
# emo <- c("ANGER", "RELAXATION", "DEPRESSION", "ENTHUSIASM", "TRIUMPH", "JOY", "FEAR", "EMPATHY", "DISGUST")
tunteet <- c("VIHA_rsp", "RENTOUTUNEISUUS_rsp", "SURU_rsp", "INNOSTUNEISUUS_rsp", 
             "VOITTO_rsp", "ILO_rsp", "PELKO_rsp", "EMPATIA_rsp", "INHO_rsp")
emo <- c("ANGER_rsp", "RELAXATION_rsp", "DEPRESSION_rsp", "ENTHUSIASM_rsp", 
         "TRIUMPH_rsp", "JOY_rsp", "FEAR_rsp", "EMPATHY_rsp", "DISGUST_rsp")

for (n in 1:length(typstr)){
  eda <- read_all_recordings(datapath, typstr[n], 'txt', delim = "\t")
  emootio <- unique(eda$Event.Name) == tunteet[1]
  if (any(emootio))
    edaemo <- tunteet
  else
    edaemo <- emo
  
  for (m in 1: length(edaemo)) {
    idx = which(eda$Event.Name == edaemo[m], arr.ind=TRUE)
    tmp <- eda[idx, -1]
    tmp$event <- str_replace(tolower(emo[m]), "_rsp", "")
    eda_all <- rbind(eda_all, tmp) 
  }
}

sort(eda_all$Event.NID)
eda_sort <- eda_all %>%
  arrange(Event.Name, Event.NID) %>% 
  rename("ts" = File) %>% 
  group_by(Part, event) %>% 
  mutate(trial=rep(seq(1, length(unique(Event.NID))), each=5), ID=round(Part/100))

rm(eda, eda_all, tmp, datapath, edaemo, emootio, m, n, times, typstr)
