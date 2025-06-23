Pipeline for processing and annotation of variant mouse tumor data (mm10)
============================

Pipeline utilizes Snakemake for indexing and tracking files of different portions of the pipeline. Docker is used for version control of the entire process as it utilizes specific versions of IonTorrent TVC & Snakemake (modern Ubuntu [20.0+] don't play nice with older dependencies). Variant calling is done for genotyping SNPs to force the set of ~500 SNPs to be in the VCF. This is a requirement for the downstream analysis of strain using ADMIXTURE and failed variant calls due to some SNPs residing in homopolymer regions. Default parameters were used for TVC - json file below.

After variant calling, VCF is filtered and annotated using bcftools and annovar. Population or common SNVs annotated are from the Mouse Genome Project. R scripts are used to create specific tables to keep track of samples used for Snakemake. The compatible version of R and necessary packages are created by the Dockerfile. Different Snakefiles are included for the calling (annotationSnakefileV2) and annotation (combinedAnno) separately.


Note: most of the code can be found in directory with original file names listed in 
```
/mnt/DATA6/mouseData/variant.Dockerfile3
```

