#!/usr/bin/env Rscript

library(jsonlite);
library(stringr);
library(vcfR);

pathToZeus <- "/mnt/DATA6/Yoda_data_dump/"
pathToYoda <- "/mnt/DATA6/Yoda_data_dump/";
pathToEros <- "/mnt/DATA3/eros_tmp/";
#pathToCetus <- "/mnt/DATA3/cetus_data_dump/"

#listofSequencers <- c(pathToYoda, pathToEros, pathToCetus);
listofSequencers <- c(pathToEros, pathToZeus, pathToYoda);

listOfBeds <- NULL

for(i in seq_along(listofSequencers)){
  setwd(listofSequencers[i]);
  list3 <- system('find . -name *.gc.bed*  | grep "local_beds" | grep -v "dummyCov"', intern = TRUE);
  list3 <- sub("./",listofSequencers[i], list3);
  
  list3_1 <- str_remove_all(list3, "plugin_out.*")
  
  list3_2 <- cbind(list3_1, list3)
  listOfBeds <- rbind(listOfBeds, list3_2)
}

listOfBeds <- as.data.frame(listOfBeds, stringsAsFactors = FALSE)
if (length(which(duplicated(listOfBeds$directories))) > 0) {
  listOfBeds <- listOfBeds[-which(duplicated(listOfBeds$directories)), ]
}
colnames(listOfBeds) <- c("directories", "bed")
### can intserct the list of directories that use different mouse bed files
mouseIndices <- grep("IAD124056_167_Designed.gc.bed", listOfBeds$bed)
mouseIndices2 <- grep("IAD202670_167_Designed.gc.bed", listOfBeds$bed)
humanIndice <- grep("OCAPlus.20191203.designed.gc.bed", listOfBeds$bed)
humanIndice2 <- grep("4477685_CCP_designed.gc.bed", listOfBeds$bed)
### hoenstly don't know why I did 80 specifcally
# humanIndice2 <- humanIndice2[-which(humanIndice2 == 80)]
humanIndice3 <- grep("IAD203665_173_Designed.gc.bed", listOfBeds$bed)
humanIndice4 <- grep("WG_IAD127899.20170720.designed.gc.bed", listOfBeds$bed)
humanIndice5 <- grep("CCP.gc.bed", listOfBeds$bed)
allIndices <- c(mouseIndices, mouseIndices2, humanIndice, humanIndice2, humanIndice3, humanIndice4, humanIndice5)

mouseBeds <- listOfBeds[allIndices,]
mouseBeds$reports <- sapply(mouseBeds$directories, FUN = function(x) unlist(str_split(x, "/"))[5])
mouseBeds$snakemakeInput <- str_remove(mouseBeds$bed, "local_beds.*")

summaryFileList <- NULL
variantDirList <- NULL
for (i in mouseBeds$directories) {
  setwd(i)
  summaryFile <- system('find . -name *bc_summary.xls | grep -v "scraper" | grep -v "dummyCov"', intern = TRUE)
  summaryFile <- sub("./", i, summaryFile)
  if (length(summaryFile) > 1) {
    summaryFile <- summaryFile[which(nchar(summaryFile) == max(nchar(summaryFile)))]
    if (length(summaryFile) > 1) {
      summaryFile <- summaryFile[order(summaryFile, decreasing = TRUE)][1]
    }
  }
  summaryFileList <- c(summaryFileList, summaryFile)
  
  variantDir <- system('find . -type d -name variantCaller*', intern = TRUE)
  variantDir <- sub("./", i, variantDir)
  variantDir <- paste0(variantDir, "/")
  variantDirList <- c(variantDirList, variantDir)
}

print("getting variant list - done")

# 20210516: KH quick fix for reports not listed in mouse beds (?)
#summaryFileList <- summaryFileList[grep(paste(mouseBeds$directories, collapse = "|"), summaryFileList)]

print(summaryFileList)
mouseBeds$summaryFile <- summaryFileList
mouseBeds$idxFile <- paste0(mouseBeds$reports, "/", "idx.txt")
variantDirList <- variantDirList[grep(paste0(mouseBeds$reports, collapse = "|"), variantDirList)]
# doesn't match for all weirdly ... two or three off
tmpVarIdx <- str_remove(variantDirList, ".*eros_tmp\\/")
tmpVarIdx <- str_remove(tmpVarIdx, "\\/plugin_out.*")
tmpVarIdx <- str_remove(tmpVarIdx, ".*Yoda_data_dump\\/")
variantDirList <- variantDirList[match(mouseBeds$reports, tmpVarIdx)]
mouseBeds$variantDir <- variantDirList
mouseBeds$bed2 <- str_remove(mouseBeds$bed, ".*local_beds\\/")


### create table for each report I can iterate for file copying
### just use if file exist function for each entry of the should be vcf file

cpTable <- NULL
for (i in seq_along(mouseBeds$summaryFile)) {
  # print(i)
  tmpLnTable <- NULL
  tmpTable <- read.table(mouseBeds$summaryFile[i], sep = "\t", header = TRUE, stringsAsFactors = FALSE)
  if(is.null(tryCatch(setwd(mouseBeds$variantDir[i]), error = function(x) return(NULL)))){
    next()
  } else{
    setwd(mouseBeds$variantDir[i])
  }
  
  ### changing it, b/c the spaces in the names messed up copying the vcfs
  tmpTable$Sample.Name <- str_remove_all(tmpTable$Sample.Name, " ")
  
  ln1 <- system('find . -name "TSVC_variants.vcf.gz"', intern = TRUE)
  ln1 <- ln1[order(ln1)]
  ln2 <- str_replace(ln1, "./", mouseBeds$variantDir[i])
  ln3 <- NULL
  for (j in seq_along(ln1)) {
    tmpLn1 <- str_remove(ln1[j], "/IonXpress.*")
    tmpLn1 <- paste0(tmpLn1, "/",tmpTable$Sample.Name[j],".vcf.gz")
    #tmpLn1 <- paste0("/mnt/DATA6/mouseData/vcfs/", str_replace(tmpLn1, "\\.", mouseBeds$reports[i]))
    tmpLn1 <- paste0("./", str_replace(tmpLn1, "\\.", mouseBeds$reports[i]))
    print(tmpLn1)
    ln3 <- c(ln3, tmpLn1)
  }
  
  if (is.null(ln3)) {
    next()
  }
  
  tmpLnTable <- data.frame("from" = ln2, "to" = ln3, "bed" = mouseBeds$bed2[i],stringsAsFactors = FALSE)
  cpTable <- rbind(cpTable, tmpLnTable)
}

cpTable$V3 <- paste0(cpTable$from, ".tbi")
cpTable$V4 <- paste0(cpTable$to, ".tbi")
colnames(cpTable) <- c("fromVcf", "toVcf", "bed","fromTbi", "toTbi")

if(length(grep("None", cpTable$toVcf)) > 0){
  cpTable <- cpTable[-grep("None", cpTable$toVcf), ]
}

print("finished list of input for copy - done")

### from list above I iteratre and make a if exist function
### setdir of newMousePipeline - separate dir for vcfs?

setwd("/mnt/DATA6/mouseData/vcfs/")

for (i in seq_along(mouseBeds$reports)) {
  setwd("/mnt/DATA6/mouseData/vcfs/")
  if(!dir.exists(mouseBeds$reports[i])){
    system(sprintf("mkdir -m 757 %s", mouseBeds$reports[i]))
  }
}

### to preemptively remove RNA vcf calls
i <- 1769
for (i in 1:nrow(cpTable)) {
  print(i)
  tmpVcf <- vcfR::read.vcfR(cpTable$fromVcf[i]);
  if (length(grep("RNA", tmpVcf@meta)) > 0) {
    next()
  } else{
    if (!file.exists(cpTable$toVcf[i])) {
      #system(sprintf("ln -s %s %s", cpTable$fromVcf[i], cpTable$toVcf[i]))
      system(sprintf("cp %s %s", cpTable$fromVcf[i], cpTable$toVcf[i]))
    }
    if (!file.exists(cpTable$toTbi[i])) {
      #system(sprintf("ln -s %s %s", cpTable$fromVcf[i], cpTable$toVcf[i]))
      system(sprintf("cp %s %s", cpTable$fromTbi[i], cpTable$toTbi[i]))
    }
  }
}

setwd("/mnt/DATA6/mouseData/vcfs/")
for (i in 1:nrow(mouseBeds)) {
  setwd(mouseBeds$reports[i])
  print(getwd())
  if (!file.exists("bedfile.txt")) {
    bedName <- sub(x = mouseBeds$bed[i], pattern = ".*local_beds/", replacement = "")
    writeLines(con = "bedfile.txt", text = bedName)
  }
  setwd("/mnt/DATA6/mouseData/vcfs/")
}

partFullPath <- getwd()
vcfList <- system('find -maxdepth 2 -name *vcf.gz | grep -v "norm"', intern = TRUE)
vcfList <- sub(vcfList, pattern = "\\.", replacement = partFullPath)
snakeFileOut <- sub(x = vcfList, pattern = "\\.vcf\\.gz", replacement = "")
tableForSnakemake <- data.frame("filename" = snakeFileOut, stringsAsFactors = FALSE)

reportName <- str_remove(tableForSnakemake$filename, "/mnt/DATA6/mouseData/vcfs/")
reportName <- str_remove(reportName, "/.*")

tableForSnakemake$report <- reportName


mouseSplit <- mouseBeds$reports[which(mouseBeds$bed2 %in% c("IAD124056_167_Designed.gc.bed", "IAD202670_167_Designed.gc.bed"))]
tableForSnakemakeMm <- tableForSnakemake[which(tableForSnakemake$report %in% mouseSplit), ]
### maybe append instead of rewriting later ..
write.table(tableForSnakemakeMm, "/mnt/DATA6/mouseData/mouseVcfTable.txt", sep = "\t",
            quote = FALSE, row.names = FALSE, col.names = TRUE)


humanSplit <- mouseBeds$reports[which(mouseBeds$bed2 %in% c("OCAPlus.20191203.designed.gc.bed", "4477685_CCP_designed.gc.bed",
                                                            "IAD203665_173_Designed.gc.bed", "WG_IAD127899.20170720.designed.gc.bed",
                                                            "CCP.gc.bed"))]
tableForSnakemakeHg <- tableForSnakemake[which(tableForSnakemake$report %in% humanSplit), ]
write.table(tableForSnakemakeHg, "/mnt/DATA6/mouseData/humanVcfTable.txt", sep = "\t",
            quote = FALSE, row.names = FALSE, col.names = TRUE)


### problem for humans is reports with both DNA and RNA, there are still vcf files 
### created for them, but they break bcftools b/c the amplicons are not found on ref hg19



