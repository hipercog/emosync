library(tidyverse)
library(R.matlab)

basepath <- '~/Benslab/EMOSYNC/MethLounge/'
setwd(basepath)

# EDA
times <- c('1to3', '3to5', '5to7', '7to9', '9to11')
typstr <- '602_autobio_era'

eda <- read_all_recordings(basepath, paste0(typstr, '.*', 'to'), 'txt')
eda.viha <- eda %>% 
  filter(Event.Name == "VIHA") %>% 
  group_by(File) %>%
  summarise_if(is.numeric, mean, na.rm=TRUE) %>%
  rename_if(is.numeric, ~paste0("avg_", .))

# EMG
s6emg <- read.csv('EMG00601.csv')
idx = which(s6emg$sampevs == "VIHA", arr.ind=TRUE)
emg <- s6emg[seq(idx[1], idx[1]+49), -1]
for (i in 2:length(idx)){
  emg <- rbind(emg, s6emg[seq(idx[i], idx[i]+49), -1])
}
emg <- s6emg %>% slice()
emg <- s6emg %>% group_by(sampevs) %>% top_n(50) 
emg <- s6emg %>% filter(sampevs %in% "VIHA")


ggplot(df, aes(x = factor(Event.Name), y = Global.Mean)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': Global Mean'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-GlobalMean'), device = 'png')
