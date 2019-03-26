library(lubridate)
library(colibri)
source('read_parse_data.R')

basepath <- "/home/bcowley/Benslab/EMOSYNC/DYNECOM/ECGedf/"
setwd(basepath)

file_list <- list.files(pattern = ".*edf") #, full.names = TRUE)

for (fname in file_list)
{
  ## read the data
  recording <- read.data.edf(fname)
  recording$signal$ECG$data <- -recording$signal$ECG$data  ## need to flip the polarity
  
  ## detect the R-peaks
  recording <- ibi_from_ecg(recording)
  
  ## remove artifacts
  ibi_orig <- recording$signal$ibi
  
  ind.artifact <- detect_artifacts_xu(recording$signal$ibi$data)
  if (length(ind.artifact) > 0)
  {
    recording$signal$ibi$data <- recording$signal$ibi$data[-ind.artifact]
    recording$signal$ibi$t <- recording$signal$ibi$t[-ind.artifact]
  }
  
}


## plot ecg with R-peaks
x11()
par(mfrow = c(3, 1))

plot(recording$signal$ECG$t[1:3000],
     recording$signal$ECG$data[1:3000], type = "l", col = "blue", lwd = 1)
points(recording$signal$ibi.amp$t[1:31],
       recording$signal$ibi.amp$data[1:31], type = "p", col = "red", cex = 2,
       pch = 20)

plot(ibi_orig$t, ibi_orig$data, type = "l", col = "red", lwd = 1)

plot(recording$signal$ibi$t, recording$signal$ibi$data, type = "l",
     col = "red", lwd = 1)

## Add a block
##
## $ time.start    : POSIXct[1:1], format: "1985-01-01 21:58:17"
## $ time.stop     : POSIXct[1:1], format: "1985-01-02 09:20:17"

block_1 <- create_block_simple(starttime = "19850101T223000",
                               starttype = "timestamp",
                               stoptime  = "19850101T233000",
                               stoptype  = "timestamp",
                               tasktype  = "sleep (start of night)",
                               part = 1,
                               meas = 1,
                               blockid = 1,
                               subject = NA,
                               casename = "demo01",
                               recording = NULL)

block_2 <- create_block_simple(starttime = "19850102T045000",
                               starttype = "timestamp",
                               stoptime  = "19850102T052500",
                               stoptype  = "timestamp",
                               tasktype  = "sleep (end of night)",
                               part = 1,
                               meas = 2,
                               blockid = 1,
                               subject = NA,
                               casename = "demo01",
                               recording = NULL)

recording <- create_block_structure(recording)

## Visalise the blocks
b1s <- block_to_seconds(recording, block_1)
b2s <- block_to_seconds(recording, block_2)

x11()
plot(recording$signal$ibi$t, recording$signal$ibi$data, type = "l")
abline(v = c(b1s$starttime, b1s$stoptime), col = "red", lwd = 5)
abline(v = c(b2s$starttime, b2s$stoptime), col = "red", lwd = 5)

## set start time to UTC
recording$properties$time.start <-
  force_tz(recording$properties$time.start, "UTC")
recording$properties$time.stop <-
  force_tz(recording$properties$time.stop, "UTC")

## set the zerotime
recording <- recording_set_zerotime(recording, timestamp =
                                      str_to_timestamp("19850101T215817 EEST"))
recording <- add_block(recording, block_1)
recording <- add_block(recording, block_2)


## analyze the recording
## Settings
settings                 <- settings_template_hrv()
settings$segment.length  <- 30
settings$segment.overlap <- 0
recording$conf$settings  <- settings

## Analyze the recording
cat("\t analyzing ibi data\n")
recording <- analyze_recording(recording, settings, signal = "ibi",
                               analysis.pipeline = analysis_pipeline_ibi)
results <- collect_results(recording)
#graphics.off()

## Visualise results
x11()
par(mfrow = c(2, 1))
plot_metric(recording, metric = "mean", filename = NULL, blockid = 1,
            new.plot = FALSE)
plot_metric(recording, metric = "mean", filename = NULL, blockid = 2,
            new.plot = FALSE)

x11()
library(ggplot2)
res_mean <- subset(results, variable == "meanhr")
p <- ggplot(res_mean, aes(value, fill = tasktype))
p <- p + geom_density()
p <- p + theme_bw()
print(p)
