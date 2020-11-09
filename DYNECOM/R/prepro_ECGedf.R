library(lubridate)
library(colibri)
library(tidyverse)

# Data is not stored in the emosync repository and is therefore two folders up, and then at the following path:
basepath <- "../../DYNECOM"
datapath <- paste0(basepath, "/ECGedf/")

file_list <- list.files(path = datapath, pattern = ".*6min.edf") #, full.names = TRUE)
PLOT_RAW <- TRUE
WNDW <- 60

# logf <- "log_file.txt"
plotdir <- paste0(basepath, "ECGplots/")
if (!dir.exists(plotdir))
   dir.create(plotdir, FALSE)
csvdir <- paste0(basepath, "HRVcsv/")
if (!dir.exists(csvdir))
  dir.create(csvdir, FALSE)

# DEBUG
# fname <- 'DCVRa_D_both_0001-ECG-6min.edf'
# results <- vector("list", length(file_list))
START <- 1
file_list <- file_list[START:length(file_list)]
i = START - 1

for (fname in file_list)
{
  i = i+1
  fname_sans_ext <- tools::file_path_sans_ext(fname)
  part_num <- as.numeric(gsub("[^0-9]", "", substr(fname, 1, 18)))
  ## read the data
  recording <- read.data.edf(fname)
  recording$signal$ECG$data <- -recording$signal$ECG$data  ## need to flip the polarity
  
  ## detect the R-peaks
  recording <- tryCatch({
    ibi_from_ecg(recording) 
  }, error = function(e){ 
    print(paste(i, ":: FAIL ::", fname_sans_ext, ":: MYSTERIOUS ERROR IN ibi_from_ecg()!!"))
    return(e)
  })
  if(inherits(recording, "error")) next
  
  ## remove artifacts
  ibi_orig <- recording$signal$ibi
  
  ind.artifact <- detect_artifacts_xu(recording$signal$ibi$data)
  if (length(ind.artifact) > 0)
  {
    recording$signal$ibi$data <- recording$signal$ibi$data[-ind.artifact]
    recording$signal$ibi$t <- recording$signal$ibi$t[-ind.artifact]
  }
  ## plot ecg with R-peaks
  if (PLOT_RAW)
  {
    png(file = paste0(plotdir, fname_sans_ext, ".png"), width = 1000, height = 1000)
    par(mfrow = c(3, 1))
    plot(recording$signal$ECG$t, recording$signal$ECG$data, type = "l", col = "blue", lwd = 1)
    points(recording$signal$ibi.amp$t,recording$signal$ibi.amp$data, type = "p", col = "red", cex = 2, pch = 20)
    plot(ibi_orig$t, ibi_orig$data, type = "l", col = "red", lwd = 1)
    plot(recording$signal$ibi$t, recording$signal$ibi$data, type = "l", col = "red", lwd = 1)
    dev.off()
  }
  ## calculate whether denoised data can be used to estimate results
  # number of sliding windows X with Y overlap in N-element vector is given by N-Y / X-Y
  # in 6 mins (360 secs) you get 11 windows of 60 secs with 50% overlap
  END_IBI <- tail(recording$signal$ibi$t, 1)
  if (END_IBI < 260) # this data cannot provide 11 windows of data with overlap <= 40
  {
    print(paste(i, ":: FAIL ::", fname_sans_ext, ":: AFTER DE-NOISING, DATA IS TOO SHORT TO ANALYZE!!"))
    next
  }else{
    OVERLAP <- round((660 - END_IBI) / 10) + 1
  }
  ## Add a block
  block_1 <- create_block_simple(starttime = format(recording$properties$time.start, format = "%Y%m%dT%H%M%S"),
                                 starttype = "timestamp",
                                 stoptime  = format(recording$properties$time.start + round(END_IBI) - 1, format = "%Y%m%dT%H%M%S"),
                                 stoptype  = "timestamp",
                                 tasktype  = substr(fname, 1, 12),
                                 part = part_num,
                                 meas = 3,
                                 blockid = 1,
                                 subject = NA,
                                 casename = fname_sans_ext,
                                 recording = NULL)
  recording <- create_block_structure(recording)
  ## set the zerotime
  recording <- recording_set_zerotime(recording, timestamp = recording$properties$zerotime)
  recording <- add_block(recording, block_1)
  
  ## analyze the recording
  ## Settings
  settings                 <- settings_template_hrv()
  settings$segment.length  <- WNDW
  settings$segment.overlap <- OVERLAP
  recording$conf$settings  <- settings
  
  ## Analyze the recording
  recording <- analyze_recording(recording, settings, signal = "ibi", analysis.pipeline = analysis_pipeline_ibi)
  results <- collect_results(recording)
  print(paste(i, ":: SUCCESS ::", fname_sans_ext, "::", tail(results$segmentid, 1), "windows of length", WNDW, "and overlap", OVERLAP))
  
  results <- filter(results, variable %in% c("stdevhr", "rmssd")) %>% 
    select(value, segment, variable, part, meas, tasktype) %>% 
    spread(variable, value)
  write.csv(results, paste0('HRVcsv/', fname_sans_ext, '.csv'))
  
}

