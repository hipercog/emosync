library(tidyverse)
library(R.matlab)

basepath <- '~/Benslab/EMOSYNC/'
setwd(basepath)
datapath <- 'MethLounge_demoData/'

# EDA
times <- c('1to3', '3to5', '5to7', '7to9', '9to11')
typstr <- '602_autobio_era'

eda <- read_all_recordings(datapath, paste0(typstr, '.*', 'to'), 'txt', delim = "\t")
eda.viha <- eda %>% 
  filter(Event.Name == "VIHA") %>% 
  group_by(File) %>%
  summarise_if(is.numeric, mean, na.rm=TRUE) %>%
  rename_if(is.numeric, ~paste0("avg_", .))

# EMG
s06emg <- read.csv(paste0(datapath, 'EMG00601.csv'))
idx = which(s06emg$sampevs == "VIHA", arr.ind=TRUE)
emg <- s06emg[seq(idx[1], idx[1]+49), -1]
emg$emo <- "anger"
emg$trial <- rep(1, nrow(emg))
emg$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
for (i in 2:length(idx)){
  tmp = s06emg[seq(idx[i], idx[i]+49), -1]
  tmp$emo <- "anger"
  tmp$trial = rep(i, nrow(tmp))
  tmp$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
  emg <- rbind(emg, tmp)
}
idx = which(s06emg$sampevs == "SURU", arr.ind=TRUE)
emg <- s06emg[seq(idx[1], idx[1]+49), -1]
emg$emo <- "sadness"
emg$trial <- rep(1, nrow(emg))
emg$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
for (i in 2:length(idx)){
  tmp = s06emg[seq(idx[i], idx[i]+49), -1]
  tmp$emo <- "sadness"
  tmp$trial = rep(i, nrow(tmp))
  tmp$sec <- c(rep(1, 10), rep(2, 10), rep(3, 10), rep(4, 10), rep(5, 10))
  emg <- rbind(emg, tmp)
}

emg.viha <- group_by(emg, sec) %>% 
  summarise_at(1:3, mean) %>%
  rename_at(2:4, ~paste0("avg_", .))

require(corrgram)
corrMatrix("SCR", eda.viha$avg_CDA.SCR,
           "SCRmax", eda.viha$avg_CDA.PhasicMax, 
           "fEMG.zyg", emg.viha$avg_zy6,
           "fEMG.cor", emg.viha$avg_co6,
           "fEMG.orb", emg.viha$avg_or6,
           title = "SCR vs EMG")


df <- cbind(eda.viha, emg.viha)
df <- select(df, avg_CDA.SCR, avg_CDA.PhasicMax, avg_zy6, avg_co6, avg_or6)

# Correlation matrix plot sapproach from http://www.sthda.com/english/wiki/ggplot2-quick-correlation-matrix-heatmap-r-software-and-data-visualization
library(reshape2)
cormat <- round(cor(df), 2)
mlt_df <- melt(cormat)
ggplot(data = mlt_df, aes(x=Var1, y=Var2, fill=value)) + 
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 12, hjust = 1))+
  coord_fixed()

# reorder cormat by corr coef to identify patterns in the matrix. hclust for hierarchical clustering order
reorder_cormat <- function(cormat){
  # Use correlation between variables as distance
  dd <- as.dist((1-cormat)/2)
  hc <- hclust(dd)
  cormat <-cormat[hc$order, hc$order]
}
get_upper_tri <- function(data2){
  total <- data2
  total[lower.tri(total)]<- NA
  return(total)
}

# Reorder the correlation matrix
upper_tri <- get_upper_tri(cormat)
cormat <- reorder_cormat(cormat)
# Melt the correlation matrix
melted_cormat <- melt(upper_tri, na.rm = TRUE)
# Create a ggheatmap
ggheatmap <- ggplot(melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "white")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal()+ # minimal theme
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()
# Print the heatmap
print(ggheatmap)

ggheatmap + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.grid.major = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(),
    axis.ticks = element_blank(),
    legend.justification = c(1, 0),
    legend.position = c(0.6, 0.7),
    legend.direction = "horizontal")+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))
