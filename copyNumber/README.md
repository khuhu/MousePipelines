Copy-number pipeline
============================

Adapted from Dan's script [Grasso et. al], and which calls and graphs gene-level copy-number. G/C corrected amplicons from the main script, 20200908mouseCnaScript.R are used for segmenting. These ratios are based on the tumor/normal amplicons which are from a pooled set of normals. Segmentation is subsequently used to call aneuploidy arm status [Hu et. al ].

Tried and implemented, but not part of automation - Strata's pool based normalization.