library(tidyr)
library(tidyverse)

#read the physiological data
polku <- '/Users/niinapeltonen/Desktop/Gradu/gradu-data/ppac_all.csv'
tiedosto <- read.csv(polku, header = T, sep = ",")

#function for calculating the z_scores
zscor <- function(x){
  out <- (x - mean(x)) / sd(x)
  out
}

#all data with the new columns for the z_scores
kaikkiarvot <- tiedosto %>%
  group_by(ID) %>%
  mutate(z_zyg_avg = zscor(zyg_avg), z_orb_avg = zscor(orb_avg),
         z_crg_avg = zscor(crg_avg), z_fasym_abs = zscor(fasym_abs),
         z_fasym_rel = zscor(fasym_rel), z_CDA.SCR = zscor(CDA.SCR),
         z_CDA.Tonic = zscor(CDA.Tonic), z_Global.Mean = zscor(Global.Mean))

#group by based on ID and emo
#calculate one value (mean) for comparing physiology and performance
uusi <- kaikkiarvot %>%
  group_by(ID, event) %>%
  summarise_at(c("zyg_avg", "orb_avg", "crg_avg", "fasym_abs", "fasym_rel", "CDA.SCR", "CDA.Tonic", "Global.Mean"), mean, na.rm = TRUE)

#same for z_scores
z_uusi <- kaikkiarvot %>%
  group_by(ID, event) %>%
  summarise_at(c("z_zyg_avg", "z_orb_avg", "z_crg_avg", "z_fasym_abs", "z_fasym_rel", "z_CDA.SCR", "z_CDA.Tonic", "z_Global.Mean"), mean, na.rm = TRUE)

#new table for means
kokodata <- merge(uusi, z_uusi, by= c("ID", "event"))
kokodata <- kokodata[order(kokodata$ID),]

#summarize performance columns for calculating the correlations
performance <- tiedosto %>%
  group_by(ID) %>%
  summarise_at(c("correct_ari", "correct_vis"), mean, na.rm = TRUE)

#filter emos for calculating correlations
anger <- kokodata %>%
  filter(event== "anger")

triumph <- kokodata %>%
  filter(event=="triumph")

joy <- kokodata %>%
  filter(event=="joy")

fear <- kokodata %>%
  filter(event=="fear")

empathy <- kokodata %>%
  filter(event=="empathy")

enthusiasm <- kokodata %>%
  filter(event=="enthusiasm")

relaxation <- kokodata %>%
  filter(event=="relaxation")

depression <- kokodata %>%
  filter(event=="depression")

disgust <- kokodata %>%
  filter(event=="disgust")

#some correlation testing
round(cor(anger$fasym_abs, performance$correct_ari), 2)

round(cor(anger$fasym_abs, performance$correct_vis), 2)

