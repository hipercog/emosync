library(tidyr)
library(tidyverse)
library(lmerTest)
library(lme4)
library(MuMIn)
library(lattice)
library(lsa)
library(mvnormtest)
library(devtools)
library(ggplot2)
library(reshape2)
library(naniar)
library(corrplot)
library(here)

polku <- file.path(here(), 'data', 'ppac_all.csv')
tiedosto <- read.csv(polku, header = T, sep = ",")

source(file.path(here(), 'R', 'cossim_sync_method_functions.R'))
source(file.path(here(), 'R', 'znbnz_utils.R'))

#new column for classifying emotions
tiedosto2 <- tiedosto %>%
  mutate(motivation=case_when(event=="anger" ~ "approach", 
                              event=="depression" ~ "neutral",
                              event=="disgust" ~ "withdrawal",
                              event=="fear" ~ "withdrawal",
                              event=="triumph" ~ "approach",
                              event=="joy" ~ "approach",
                              event=="enthusiasm" ~ "approach",
                              event=="empathy" ~ "neutral",
                              event=="relaxation" ~ "neutral")) %>%
  mutate(valence=case_when(event=="anger" ~ "neg", 
                           event=="depression" ~ "neg",
                           event=="disgust" ~ "neg",
                           event=="fear" ~ "neg",
                           event=="triumph" ~ "pos",
                           event=="joy" ~ "pos",
                           event=="enthusiasm" ~ "pos",
                           event=="empathy" ~ "pos",
                           event=="relaxation" ~ "pos")) %>%
  mutate(arousal=case_when(event=="anger" ~ "high", 
                           event=="depression" ~ "low",
                           event=="disgust" ~ "high",
                           event=="fear" ~ "high",
                           event=="triumph" ~ "high",
                           event=="joy" ~ "high",
                           event=="enthusiasm" ~ "high",
                           event=="empathy" ~ "low",
                           event=="relaxation" ~ "low")) %>%
  mutate(valence_arousal = interaction(valence, arousal)) %>%
  mutate(motivation_valence = interaction(motivation, valence)) %>%
  select(ID, event, motivation, valence, arousal, valence_arousal, motivation_valence, everything()) #reorganize columns

#ditch outlier
tiedosto2$visRTV[1:270] = NA 

#cosine similarity values between categorized emotions
#classified emotions
cos_sim_app_withd <- niina_feature_wrangler2(tiedosto2, "approach", "withdrawal", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_neut_app <- niina_feature_wrangler2(tiedosto2, "neutral", "approach", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_neut_withd <- niina_feature_wrangler2(tiedosto2, "neutral", "withdrawal", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_pos_neg <- niina_feature_wrangler2(tiedosto2, "pos", "neg", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))

#negative emotions 
cos_sim_fear_disg <- niina_feature_wrangler2(tiedosto2, "fear", "disgust", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_fear_angr <- niina_feature_wrangler2(tiedosto2, "fear", "anger", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_disg_angr <- niina_feature_wrangler2(tiedosto2, "disgust", "anger", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))

#positive emotions
cos_sim_enthus_joy <- niina_feature_wrangler2(tiedosto2, "enthusiasm", "joy", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_triumph_joy <- niina_feature_wrangler2(tiedosto2, "triumph", "joy", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_enthus_triumph <- niina_feature_wrangler2(tiedosto2, "enthusiasm", "triumph", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))

#neutral emotios
cos_sim_empat_relax <- niina_feature_wrangler2(tiedosto2, "empathy", "relaxation", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_depr_relax <- niina_feature_wrangler2(tiedosto2, "depression", "relaxation", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_empat_depr <- niina_feature_wrangler2(tiedosto2, "empathy", "depression", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))

#mixed feelings
cos_sim_empat_angr <- niina_feature_wrangler2(tiedosto2, "empathy", "anger", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_empat_triumph <- niina_feature_wrangler2(tiedosto2, "empathy", "triumph", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_angr_joy <- niina_feature_wrangler2(tiedosto2, "anger", "joy", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_depr_fear <- niina_feature_wrangler2(tiedosto2, "depression", "fear", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_depr_disg <- niina_feature_wrangler2(tiedosto2, "depression", "disgust", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))

cos_sim_relax_angr <- niina_feature_wrangler2(tiedosto2, "relaxation", "anger", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_relax_joy <- niina_feature_wrangler2(tiedosto2, "relaxation", "joy", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_relax_fear <- niina_feature_wrangler2(tiedosto2, "relaxation", "fear", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_relax_disg <- niina_feature_wrangler2(tiedosto2, "relaxation", "disgust", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))
cos_sim_relax_triumph <- niina_feature_wrangler2(tiedosto2, "relaxation", "triumph", c(CDA.SCR, zyg_avg, orb_avg, crg_avg, F4_P8_12_rel, F3_P8_12_rel))

####
#EEG asymmetry

cos_sim_asym <- niina_feature_wrangler2(tiedosto2, "pos", "neg", c(F4_P8_12_rel, F3_P8_12_rel))
cos_sim_asym2 <- niina_feature_wrangler2(tiedosto2, "approach", "withdrawal", c(F4_P8_12_rel, F3_P8_12_rel))

#table for cosine similarity values
cos_sim_values <- cbind(cos_sim_app_withd, cos_sim_neut_app,
                        cos_sim_neut_withd, cos_sim_pos_neg, cos_sim_fear_disg,
                        cos_sim_fear_angr, cos_sim_disg_angr, cos_sim_enthus_joy,
                        cos_sim_triumph_joy, cos_sim_enthus_triumph, cos_sim_empat_relax,
                        cos_sim_depr_relax, cos_sim_empat_depr, cos_sim_empat_angr,
                        cos_sim_empat_triumph, cos_sim_angr_joy, cos_sim_depr_fear, cos_sim_depr_disg,
                        cos_sim_relax_angr, cos_sim_relax_joy, cos_sim_relax_fear, cos_sim_relax_disg,
                        cos_sim_relax_triumph, cos_sim_asym, cos_sim_asym2)

cos_sim_values <- cos_sim_values[,-c(3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49)]
names(cos_sim_values) <- c('ID','app_withd', 'neut_app', 
                           'neut_withd', 'pos_neg', 'fear_disg', 'fear_angr',
                           'disg_angr', 'enthus_joy', 'triumph_joy', 'enthus_triumph',
                           'empat_relax', 'depr_relax', 'empat_depr',
                           'empat_angr', 'empat_triumph', 'angr_joy', 'depr_fear', 'depr_disg', 
                           'relax_angr', 'relax_joy', 'relax_fear', 'relax_disg', 'relax_triumph',
                           'asym_neg_pos', 'asym_app_withd')

#new table for perfomance scores (to be able to use cbind)
perf <- unique.data.frame(tiedosto2[,c(1,23:32)])
perftable <- perf[-c(10, 12, 19, 24), ]   #remove participants who don't have cos_sim value

#combine cosine similarity values and performance scores   
cos_perf <- cbind(cos_sim_values, perftable)
cos_perf <- cos_perf[,-27]


#Correlograms

categorized_neg <- corrMatrix("app_withd", cos_perf$app_withd,
                              "neut_app", cos_perf$neut_app,
                              "neut_withd", cos_perf$neut_withd,
                              "pos_neg", cos_perf$pos_neg,
                              "fear_disg", cos_perf$fear_disg,
                              "fear_angr", cos_perf$fear_angr,
                              "disg_angr", cos_perf$disg_angr,
                              "depr_fear", cos_perf$depr_fear,
                              "depr_disg", cos_perf$depr_disg)


categorized_pos <- corrMatrix("app_withd", cos_perf$app_withd,
                              "neut_app", cos_perf$neut_app,
                              "neut_withd", cos_perf$neut_withd,
                              "pos_neg", cos_perf$pos_neg,
                              "enthus_joy", cos_perf$enthus_joy,
                              "triumph_joy", cos_perf$triumph_joy,
                              "enthus_triumph", cos_perf$enthus_triumph,
                              "empat_triumph", cos_perf$empat_triumph)

categorized_leftovers <- corrMatrix("app_withd", cos_perf$app_withd,
                                    "neut_app", cos_perf$neut_app,
                                    "neut_withd", cos_perf$neut_withd,
                                    "pos_neg", cos_perf$pos_neg,
                                    "empat_relax", cos_perf$empat_relax,
                                    "empat_depr", cos_perf$empat_depr,
                                    "empat_angr", cos_perf$empat_angr,
                                    "empat_triumph", cos_perf$empat_triumph)

categorized_mixed <- corrMatrix("app_withd", cos_perf$app_withd,
                                "neut_app", cos_perf$neut_app,
                                "neut_withd", cos_perf$neut_withd,
                                "pos_neg", cos_perf$pos_neg,
                                "triumph_joy", cos_perf$triumph_joy,
                                "enthus_triumph", cos_perf$enthus_triumph,
                                "fear_angr", cos_perf$fear_angr,
                                "disg_angr", cos_perf$disg_angr,
                                "fear_disg", cos_perf$fear_disg)

neg_pos_high_arousal <- corrMatrix("fear_disg", cos_perf$fear_disg,
                                   "fear_angr", cos_perf$fear_angr,
                                   "disg_angr", cos_perf$disg_angr,
                                   "enthus_joy", cos_perf$enthus_joy,
                                   "triumph_joy", cos_perf$triumph_joy,
                                   "enthus_triumph", cos_perf$enthus_triumph)

neg_pos_mix <- corrMatrix("empat_relax", cos_perf$empat_relax,
                          "empat_depr", cos_perf$empat_depr,
                          "fear_angr", cos_perf$fear_angr,
                          "disg_angr", cos_perf$disg_angr,
                          "enthus_joy", cos_perf$enthus_joy,
                          "triumph_joy", cos_perf$triumph_joy,
                          "enthus_triumph", cos_perf$enthus_triumph)

neutral_high_arousal <- corrMatrix("relax_angr", cos_perf$relax_angr,
                                   "relax_joy", cos_perf$relax_joy,
                                   "relax_fear", cos_perf$relax_fear,
                                   "relax_disg", cos_perf$relax_disg,
                                   "relax_triumph", cos_perf$relax_triumph,
                                   "fear_angr", cos_perf$fear_angr,
                                   "disg_angr", cos_perf$disg_angr,
                                   "fear_disg", cos_perf$fear_disg,
                                   "enthus_joy", cos_perf$enthus_joy,
                                   "triumph_joy", cos_perf$triumph_joy,
                                   "enthus_triumph", cos_perf$enthus_triumph)

corrplot(neutral_high_arousal)

#some correlations
all_emos <- cor(tiedosto2[,c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel", "F4_P8_12_abs", "F3_P8_12_abs",  "fasym_abs", "fasym_rel")], tiedosto2[,c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs")
corrplot(all_emos, title = "whole data",mar=c(0,0,3,0), method = "number")

emp <- as.data.frame(subset(tiedosto2, event=="empathy", select=10:32))
emp_cor <- cor(emp[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], emp[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs")
corrplot(emp_cor, title = "empathy", mar=c(0,0,3,0), method = "number")

angr <- as.data.frame(subset(tiedosto2, event=="anger", select=10:32))
angr_cor <- round(cor(angr[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], angr[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(angr_cor, title = "anger", mar=c(0,0,3,0), method = "number")

disg <- as.data.frame(subset(tiedosto2, event=="disgust", select=10:32))
disg_cor <- round(cor(disg[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], disg[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(disg_cor, title = "disgust", mar=c(0,0,3,0), method = "number")

enth <- as.data.frame(subset(tiedosto2, event=="enthusiasm", select=10:32))
enth_cor <- round(cor(enth[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], enth[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(enth_cor, title = "enthusiasm", mar=c(0,0,3,0), method = "number")

joy <- as.data.frame(subset(tiedosto2, event=="joy", select=10:32))
joy_cor <- round(cor(joy[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], joy[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(joy_cor, title = "joy", mar=c(0,0,3,0), method = "number")

fear <- as.data.frame(subset(tiedosto2, event=="fear", select=10:32))
fear_cor <- round(cor(fear[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], fear[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(fear_cor, title = "fear", mar=c(0,0,3,0), method = "number")

tri <- as.data.frame(subset(tiedosto2, event=="triumph", select=10:32))
tri_cor <- round(cor(tri[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], tri[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(tri_cor, title = "triumph", mar=c(0,0,3,0), method = "number")

relax <- as.data.frame(subset(tiedosto2, event=="relaxation", select=10:32))
relax_cor <- round(cor(relax[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], relax[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(relax_cor, title = "relaxation", mar=c(0,0,3,0), method = "number")

dep <- as.data.frame(subset(tiedosto2, event=="depression", select=10:32))
dep_cor <- round(cor(dep[, c("CDA.SCR", "zyg_avg", "orb_avg", "crg_avg", "F4_P8_12_rel", "F3_P8_12_rel")], dep[, c("ariRTmed", "ariRTV", "ariMaxpc", "visRTV", "visRTmed", "visN")], use = "complete.obs"), 2)

corrplot(dep_cor, title = "depression", mar=c(0,0,3,0), method = "number")

###
#calculate mean and sd for cos sim values

values <- abs(subset(cos_perf, select=fear_disg:relax_triumph))
csmn <- apply(values, 1, mean)
csmn <- as.numeric(csmn)
cssd <- apply(values, 1, sd)
cssd <- as.numeric(cssd)
cos_perf2 <- cbind(cos_perf, csmn, cssd)
