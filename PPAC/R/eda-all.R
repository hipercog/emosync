library(tidyverse)
library(R.matlab)

source('/Users/niinapeltonen/Desktop/Gradu/gradu-ohjelmat/emosync-master/PPAC/R/znbnz_utils.R')
datapath <- '/Users/niinapeltonen/Desktop/Gradu/gradu-data/PPAC_eras/'

setwd(datapath)

eda_all <- data.frame(matrix(ncol=7, nrow=0))
colnames(eda_all) <- c('1to3', '3to5', '5to7', '7to9', '9to11', 'emoeng', 'ID')

#EDA
times <- c('1to3', '3to5', '5to7', '7to9', '9to11')

typstr <- c('PPACv00105_autobio_era', 'PPACv00204_autobio_era', 'PPACv00304_autobio_era','PPACv00403_autobio_era',
            'PPACv00506_autobio_era',
            'PPACv00602_autobio_era', 'PPACv00705_autobio_era','PPACv00803_autobio_era','PPACv00902_autobio_era',
            'PPACv01003_autobio_era','PPACv01103_autobio_era','PPACv01203_autobio_era','PPACv01302_autobio_era',
            'PPACv01505_autobio_era', 'PPACv01605_autobio_era','PPACv01702_autobio_era', 'PPACv01802_autobio_era', 
            'PPACv01904_autobio_era', 'PPACv02004_autobio_era', 'PPACv02102_autobio_era', 'PPACv02203_autobio_era', 
            'PPACv02303_autobio_era', 'PPACv02604_autobio_era', 'PPACv02702_autobio_era', 'PPACv02802_autobio_era',
            'PPACv02904_autobio_era', 'PPACv03005_autobio_era', 'PPACv03104_autobio_era', 'PPACv03205_autobio_era')
tunteet_eda <- c("VIHA", "RENTOUTUNEISUUS", "SURU", "INNOSTUNEISUUS", "VOITTO", "ILO", "PELKO", "EMPATIA", "INHO")
emo_eda <- c("ANGER", "RELAXATION", "DEPRESSION", "ENTHUSIASM", "TRIUMPH", "JOY", "FEAR", "EMPATHY", "DISGUST")

for (n in 1:length(typstr)){
  eda <- read_all_recordings(datapath, typstr[n], 'txt', delim = "\t")
  emootio <- unique(eda$Event.Name) == tunteet_eda[1]
  if (any(emootio))
    edaemo <- tunteet_eda
  else
    edaemo <- emo_eda
  
  for (m in 1: length(edaemo)) {
    idx = which(eda$Event.Name == edaemo[m], arr.ind=TRUE)
    tmp <- eda[idx, -1]
    tmp$event <- tolower(emo_eda[m])
    eda_all <- rbind(eda_all, tmp) 
  }
}

sort(eda_all$Event.NID)
eda_sort <- eda_all %>%
arrange(Event.Name, Event.NID) %>% 
rename("ts" = File) %>% 
group_by(Part, event) %>% 
mutate(trial=rep(seq(1, length(unique(Event.NID))), each=5), ID=round(Part/100))
