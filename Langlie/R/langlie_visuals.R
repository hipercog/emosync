library(tidyverse)
library(readr)

basepath <- '~/Benslab/project_LANGLIE/Batchalyze/'
setwd(basepath)

times <- c('0to1', '1to2', '2to3', '3to4', '4to5', '5to6', '6to7', '3to6')
typstr <- 'R_norp'
T1toT2 <- times[6]

# for (rgx in side_time) {
rgx <- paste0(typstr, '.*', T1toT2)
print(rgx)
df <- read_all_recordings(paste0(basepath, '/ERA/'), rgx, 'txt', delim = "\t")
df <- df %>% filter(Event.Name > 9) %>% filter(Event.Name < 90) 
df$Event.Name <- factor(df$Event.Name)
levels(df$Event.Name) <- c('ftnt', 'ftnl', 'ftwt', 'ftwl', 'stnt', 'stnl', 'stwt', 'stwl')

ggplot(df, aes(x = factor(Event.Name), y = CDA.nSCR)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': CDA nSCR'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-CDA-nSCR'), device = 'png')
ggplot(df, aes(x = factor(Event.Name), y = CDA.Latency)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': CDA Latency'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-CDA-Latency'), device = 'png')
ggplot(df, aes(x = factor(Event.Name), y = CDA.SCR)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': CDA SCR'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-CDA-SCR'), device = 'png')
ggplot(df, aes(x = factor(Event.Name), y = CDA.PhasicMax)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': CDA PhasicMax'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-CDA-PhasicMax'), device = 'png')
ggplot(df, aes(x = factor(Event.Name), y = CDA.Tonic)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': CDA Tonic'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-CDA-Tonic'), device = 'png')
ggplot(df, aes(x = factor(Event.Name), y = Global.Mean)) + geom_boxplot(outlier.shape = NA) + 
  geom_point(aes(color = factor(Part)), position = position_dodge(width = 0.5)) + ggtitle(paste(rgx, ': Global Mean'))
ggsave(paste0('Figures/', typstr, '_', T1toT2, '-GlobalMean'), device = 'png')
# }