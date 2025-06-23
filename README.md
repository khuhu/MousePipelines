All pipelines for processing mouse sequencing data
============================

Both copy-number and variant calling and annotation pipelines is made for the mm10 genome and sequencing from custom IonTorrent panels. Note, for any new custom-panels, even small changes to amplicons, need to add new bed file and then alter appropriate code so that correct indexes are made for Snakemake processing. Individual pipelines will have their own subdirectories and README files. 