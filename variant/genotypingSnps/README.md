Notes about using IonTorrent TVC docker image (mm10)
============================

Uses tvc docker file in interactive mode, from there run specific script. The original tvc file should be in /br_z1/kevin_storage/mouseData/. Edits were made for lab's specific needs or naming purposes. Custom json files are needed for force calling. Should be provided in the directory.

```
docker run --mount type=bind,source=/avatar_data3/,target=/mnt/DATA3,readonly --mount type=bind,source=/br_z1/kevin_storage/genome/,target=/home/reference/ --mount type=bind,source=/br_z1/kevin_storage/mouseData/,target=/mnt/DATA6/mouseData/ -it tvc_pipelineint
```

Need to edit the snake file for (1) index file where I run specific reports (2) the custom output directory for a project. Note: reduced index file is just copy number index file i.e /br_z1/kevin_storage/mouseData/mouseBedsIdx.txt

```
tmpTable <- read.table("/br_z1/kevin_storage/mouseData/mouseBedsIdx.txt",
                        sep = "\t", stringsAsFactors = FALSE, header = TRUE)
tmpTable2 <- tmpTable[grep("Auto_user_AUS5-288-PP23_MG_541_665|Auto_user_AUS5-239-BBN_mouse_bladder_MG_493_562|Auto_user_AUS5-260-BBN_mouse_bladder_MG_2_514_605", tmpTable$reports), ]

write.table(tmpTable2, "/br_z1/kevin_storage/mouseData/bbnProjectIdx.txt",
            sep = "\t", col.names = TRUE, row.names = FALSE, quote = FALSE)
```

When creating directory for new reports, need to have reports and outdir.txt and directory.txt files. Would be easiest to copy entire report from other directories such as copynumber or vcf. Need to find easier way to auto create these; probably made using prior script

```
directory file:/mnt/DATA3/eros_tmp/Auto_user_AUS5-76-MG_test1_255_185/
outdir file:/mnt/DATA6/mouseData/tvcOutv2/Auto_user_AUS5-76-MG_test1_255_185
```

For hotspot file, just combine all variants via vcfR reading iteratively.
Example in script: 20250513processingBbnForceCalls.R. Write the vcf then use tvcutils prepare_hotspots in the docker image.
```
tvcutils prepare_hotspots --reference /home/reference/mm10/mm10_amp.fa -v ./20250511bbnHotspotFile.vcf --output-vcf ./20250511bbbHotspotTvc.vcf
```

From within the snakefile below, the main R script calls the tvc functions. Need these Following files and can change based on what is required. Can Edit desired variant calls using vcf hotspot file.

```
tvcCallParams.json
IAD202670_167_Designed.gc.bed
20210118hotspot_withHeaderV2.hotspot.vcf
mm10_amp.fa
```

run snakefile like should change based on which directories i want to run

```
snakemake --snakefile tvcCallSnakefileBbnZeroFreq -k --jobs 5
```