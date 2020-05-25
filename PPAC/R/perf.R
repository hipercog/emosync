library(tidyverse)
library(R.matlab)
library(here)
library(stringr)

source(file.path(here(), 'R', 'znbnz_utils.R'))

# Path to the data folder containing trials data in csv-format.
datapath <- file.path(str_replace(here(), 'emosync', 'project_PPAC'), 'logs')

all_logs <- list.files(datapath, all.files = T, pattern ="\\.log$")

aridf <- data.frame()
for (i in 1:length(all_logs)){
  dat <- read_delim(file.path(datapath, all_logs[i]), '\t', skip = 4, col_types = "_iccii_____")
  
  tasks <- which(dat$Code == "white noise video baseline")
  
  arith <- which(startsWith(dat$Code, "easy:"))
  if (length(arith) == 0)
    next
  else if (max(arith) > max(tasks))
    tasks <- c(tasks, nrow(dat))
  
  lo <- max(tasks[tasks < min(arith)]) + 1
  if (is.infinite(lo))
    lo <- 1
  hi <- min(tasks[tasks > max(arith)]) - 1
  if (is.infinite(hi))
    hi <- nrow(dat)

  arith <- dat[lo:hi,]
  arirp <- which(arith$`Event Type` == "Response")
  arirp <- arirp[startsWith(arith$Code[arirp - 1], "easy:") |
                   startsWith(arith$Code[arirp - 1], "mod:") |
                   startsWith(arith$Code[arirp - 1], "diff:")]
  ariRT <- arith$TTime[arirp] / 10
  ariRT <- ariRT[ariRT > 300]

  aridf <- rbind(aridf, 
              t(c(round(parse_number(all_logs[i]) / 100),
               mean(ariRT, na.rm = TRUE),
               median(ariRT, na.rm = TRUE),
               var(ariRT, na.rm = TRUE),
               length(ariRT))))
}
aridf$ariMaxpc <- (aridf$V5 / max(aridf$V5)) * 100

visdf <- data.frame()
for (i in 1:length(all_logs)){
  dat <- read_delim(file.path(datapath, all_logs[i]), '\t', skip = 4, col_types = "_iccii_____")
  
  tasks <- which(dat$Code == "white noise video baseline")

  visrc <- which(startsWith(dat$Code, "wally_"))
  if (length(visrc) == 0)
    next
  else if (max(visrc) > max(tasks))
    tasks <- c(tasks, nrow(dat))
  
  lo <- max(tasks[tasks < min(visrc)]) + 1
  if (is.infinite(lo))
    lo <- 1
  hi <- min(tasks[tasks > max(visrc)]) - 1
  if (is.infinite(hi))
    hi <- nrow(dat)

  visrc <- dat[lo:hi,]
  visrp <- which(visrc$`Event Type` == "Response")
  visrp <- visrp[(startsWith(visrc$Code[visrp - 1], "wally_") |
                    startsWith(visrc$Code[visrp - 1], "maze_") |
                    startsWith(visrc$Code[visrp - 1], "Search Pics :")) &
                   visrc$Code[visrp + 1] == "correct"]
  visRT <- visrc$TTime[visrp] / 10
  visCor <- length(which(visrc$Code == "correct"))
  visInc <- length(which(visrc$Code == "incorrect"))
  
  visdf <- rbind(visdf, 
                t(c(round(parse_number(all_logs[i]) / 100),
                    mean(visRT, na.rm = TRUE),
                    median(visRT, na.rm = TRUE),
                    var(visRT, na.rm = TRUE),
                    length(visRT),
                    visCor / (visCor + visInc))))
}

perf <- merge(aridf, visdf, by = "V1", all.x = TRUE, all.y = TRUE) %>% 
        rename("ID"=V1, 
          "ariRTmean"=V2.x, 
          "ariRTmed"=V3.x, 
          "ariRTV"=V4.x, 
          "ariN"=V5.x, 
          "visRTmean"=V2.y, 
          "visRTmed"=V3.y, 
          "visRTV"=V4.y, 
          "visN"=V5.y, 
          "visAcc"=V6)

write.csv(perf, file.path(here(), "data", "ppac_perf.csv"), row.names = FALSE)
rm(all_logs, datapath, dat, hi, lo, i, tasks, arith, aridf, arirp, ariRT, visCor, visInc, visrp, visRT, visrc, visdf)
