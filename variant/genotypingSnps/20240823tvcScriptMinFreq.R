#!/usr/bin/env Rscript

### as per the instructions by the README, need to load docker file
### utilizing variantAnalysis.py script to call specific directories




### loading in variables like desired directory to process

library(stringr)
library(optparse)

option_list = list(
  make_option(c("-d", "--directory"), type="character", default=NULL,
              help="location of bam files", metavar="character"),
  make_option(c("-o", "--outdir"), type="character", default=NULL,
              help="output location", metavar="character")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

dir <- read.table(opt$directory, stringsAsFactors = FALSE)$V1


### finding all samples

setwd(dir)
bamFiles <- system('find . -name "*.bam*" | grep -v "plugin" | grep -v "barcodes"| grep -v "bai"', intern = TRUE);
summaryFile <- read.table(system('find . -name "*.bc_summary*"', intern = TRUE), sep = "\t",
                          header = TRUE, stringsAsFactors = FALSE)

outdir <-read.table(opt$outdir, stringsAsFactors = FALSE)$V1
setwd(outdir)



summaryFile$Sample.Name2 <- str_remove_all(summaryFile$Sample.Name, " ")



### using the tvc script to call VCFs with suffix _geno.vcf

setwd(outdir)
for (i in seq_along(summaryFile$Barcode.ID)) {
  tmpBamLocation <- str_replace(bamFiles[grep(summaryFile$Barcode.ID[i], bamFiles)], "\\./", dir)
  if (file.exists(paste0(summaryFile$Sample.Name[i],"_geno.vcf"))) {
    next()
  } else{
    cmd <- paste("variant_caller_pipeline.py -b /mnt/DATA6/mouseData/bedFiles/IAD202670_167_Designed.gc.bed",
                 "-p /mnt/DATA6/mouseData/tvcCallParamsV2.json",
                 "-s /mnt/DATA6/mouseData/20210118hotspot_withHeaderV2.hotspot.vcf -z",
                 paste0(summaryFile$Sample.Name2[i],"_geno") , "-i", tmpBamLocation,
                 "-r /home/reference/mm10/mm10_amp.fa -N 10")
    system(eval(cmd))
  }
}



if(!file.exists("check.txt")){
  system(sprintf("echo 'done' > check.txt"))
}
