All pipelines for processing mouse sequencing data
============================

Both copy-number calling (gene and segment), variant calling and annotation pipelines made for the mm10 genome and sequencing from custom IonTorrent panels. Note, for any new custom-panels, even small changes to amplicons, need to add new bed file and then alter appropriate code so that correct indexes are made for Snakemake processing. Individual pipelines will have their own sub-directories and README files. 