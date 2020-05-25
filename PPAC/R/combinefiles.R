library(tidyverse)
library(R.matlab)
library(here)

source(file.path(here(), 'R', 'znbnz_utils.R'))

# corrMatrix should show that SCR =iSCR, ≃PhasixMax, ≃AmpSum
with(eda_sort, corrMatrix(
  "AmpSum", CDA.AmpSum,
  "SCR", CDA.SCR,
  "iSCR", CDA.ISCR,
  "PhsMax", CDA.PhasicMax, 
  "Tonic", CDA.Tonic,
  "TTP.AmpSum", TTP.AmpSum,
  "Mean", Global.Mean,
  "MaxDef", Global.MaxDeflection,
  title = "SCR feats"))

print(diagnose_vars(eda_sort$CDA.SCR))
print(diagnose_vars(eda_sort$CDA.Tonic))
print(diagnose_vars(eda_sort$TTP.AmpSum))
print(diagnose_vars(eda_sort$Global.Mean))
print(diagnose_vars(eda_sort$Global.MaxDeflection)) # too many zeros to use

# corrMatrix should show that EMG averages are not correlated, & diagnosis = all clear
with(emgavg, corrMatrix(
  "zyg", zyg_avg,
  "orb", orb_avg,
  "crg", crg_avg,
  title = "EMG"))

print(diagnose_vars(emgavg$zyg_avg))
print(diagnose_vars(emgavg$orb_avg))
print(diagnose_vars(emgavg$crg_avg))


# EEG diagnosis = all clear
print(diagnose_vars(eeg$fasym_abs))
print(diagnose_vars(eeg$fasym_rel))
print(diagnose_vars(eeg$F4_P8_12_abs))
print(diagnose_vars(eeg$F3_P8_12_abs))
print(diagnose_vars(eeg$F4_P8_12_rel))
print(diagnose_vars(eeg$F3_P8_12_rel))

# Get behavioural data created with perf.R
perf <- read.csv(file.path(here(), "data", "ppac_perf.csv"))

byx <- c("ID","event", "trial", "ts")
PPAC <- merge(merge(eda_sort, eeg, by=byx, all.x = TRUE, all.y = TRUE), 
              as.data.frame(emgavg), by=byx, all.x = TRUE, all.y = TRUE) %>%
  select(1:4, 
         CDA.SCR, CDA.Tonic, TTP.AmpSum, Global.Mean,
         zyg_avg, orb_avg, crg_avg,
         fasym_abs, fasym_rel, F4_P8_12_abs, F3_P8_12_abs, F4_P8_12_rel, F3_P8_12_rel) %>%
  merge(., perf, by="ID")
PPAC <- arrange(PPAC, as.numeric(ID))

write.csv(PPAC, file.path(here(), "data", "ppac_all.csv"), row.names = FALSE)
rm(byx)
