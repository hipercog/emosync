library(tidyverse)
library(R.matlab)
library(here)

source(file.path(here(), 'R', 'znbnz_utils.R'))

# Path to the data folder containing trials data in csv-format.
datapath <- file.path(str_replace(here(), 'emosync', 'project_PPAC'), 'EEG')

eeg <- read.csv(file.path(datapath, 'allBP.csv'), sep = "\t")
eeg$ID <- as.factor(eeg$ID)
eeg$trial <- as.factor(eeg$trial)
eeg$ts <- as.factor(eeg$ts)
eeg$fasym_abs <- log(eeg$F4_P8_12_abs / eeg$F3_P8_12_abs)
eeg$fasym_rel <- log(eeg$F4_P8_12_rel / eeg$F3_P8_12_rel)

rm(datapath)
