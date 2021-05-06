# Use of the SmokingDefinition algorithm
Smoking status is defined using a published algorithm available via Zenodo.org: https://doi.org/10.5281/zenodo.793392

Use of the algorithm should be cited:
> Rebecca M. Joseph, & Mohammad Movahedi. (2018, August 23). SmokingDefinition (STATA): An algorithm to define smoking status in patients of the UK Clinical Practice Research Datalink (CPRD) (Version v1.3). Zenodo. http://doi.org/10.5281/zenodo.1405937

The algorithm available through Zenodo has a CC-BY-NC-ND licence (https://creativecommons.org/licenses/by-nc-nd/4.0/).

For the current analysis, the algorithm code has been modified to run on the current datasets and in Stata 16. Details of the changes made are provided below, however the algorithm must be downloaded and modified separately. If you wish to use the SmokingDefinition algorithm you should download the original code using the link above. All changes made to individual files are highlighted within the shared files, and are summarised at the end of this file.


# SUMMARY OF CHANGES
### scripts/preparation/SmokingDefinition13/scripts/smoking_definition_master.do
- move to scripts/preparation/smoking_definition_master.do
- update file paths line 4, 5, 14
- delete lines 57-58
- insert new code after line 56:
```
*** BELOW SECTIONS NEW: RMJ added 20200124
saveold data/clean/smoking_matrix.dta, replace

frame put *, into(smoking)

*** NOW KEEP MOST RECENT UP TO OR INCLUDING THE INDEX DATE
frame create index
frame change index
use patid secondaddate using data/clean/finalcohort.dta
rename secondaddate indexdate

frame change smoking
frlink m:1 patid, frame(index)
keep if index<.
frget *, from(index)
drop index

count
keep if start <= indexdate
count

bys patid (start): keep if _n==_N
count

*** TIDY AND SAVE
keep patid smokestat
*duplicates report patid
saveold data/clean/baselinesmoking.dta, replace

capture log close smoking
frames reset
clear
exit
```
- comment-out lines 34,52,55
- add code for new script after line 23: `do $basedir/scripts/2_1_1_AdditionalDays.do'
- add frames (stata 16) commands before running each do file
```
*e.g. at line 19:
frame create smoking_readcodes	// NEW 
frame change smoking_readcodes	// NEW 
```
- add info about reuse of SmokingDefinition, line 2 onwards


### scripts/preparation/SmokingDefinition13/scripts/1_1_ImportReadcodes.do
- comment-out line 5 (save)

### scripts/preparation/SmokingDefinition13/scripts/1_2_ProductCodelist.do:
- change file path line 7
- change file path line 38
- comment-out line 49 (save)

### scripts/preparation/SmokingDefinition13/scripts/2_1_AdditionalFile.do:
- change file path/name line 8
- line 37 "drop data1" only
- line 48 also keep ad_date
- comment-out line 49 (save)
- additions after line 47:
```
drop if ad_stat==.
rename eventdate ad_date
```

### scripts/preparation/SmokingDefinition13/scripts/2_1_1_AdditionalDays.do
- new script based on 3_2_SmokingDays.do
- picks one additional record per day (do not have adid in clinical file so cannot link later)

### scripts/preparation/SmokingDefinition13/scripts/2_2_SmokingInTherapy.do
- line 5 remove sysdate and change path
- comment-out line 20 (save)
- remove lines 7-13 and replace with:
```
frlink m:1 prodcode, frame(smoking_therapy)
keep if smoking_therapy<.
frget *, from(smoking_therapy)
drop smoking_therapy
rename eventdate ther_date
```

### scripts/preparation/SmokingDefinition13/scripts/2_3_SmokingRecordMedcode.do
- comment-out lines 30-32
- comment-out line 36 (save)
- add after line 32: `sort patid re_date`
- remove lines 6-27

### scripts/preparation/SmokingDefinition13/scripts/2_4_SmokingEnttype6.do
- file not used

### scripts/preparation/SmokingDefinition13/scripts/2_5_CombineDatasources.do
- comment-out line 47 (save)
- line 35 remove consid
- replace lines 3-28 with:
```
frame change ad_prep
gen eventdate = ad_date // RMJ added 20200129
tempfile additional
save "`additional'",replace

frame change smokefiles_combined
gen eventdate = re_date

merge m:1 patid eventdate using "`additional'"
rename _merge medmerge

frame change therapy_prep
tempfile therapy
save "`therapy'", replace

frame change smokefiles_combined
preserve	// strange workaround needed as unspecified error trying to merge "`therapy'"
clear
use "`therapy'"
tempfile NEWFILE
save "`NEWFILE'", replace
restore
merge m:1 patid using "`NEWFILE'"
rename _merge thermerge
```

### scripts/preparation/SmokingDefinition13/scripts/3_1_SmokingEpisodes.do
- comment-out line 5 (use)
- comment-out lines 95-98 and replace with:
```
order patid status strength date adid enttype
sort patid date status strength
```

### scripts/preparation/SmokingDefinition13/scripts/3_2_SmokingDays.do
- comment-out line 7 (use)
- comment-out lines 10-11
- comment-out lines 26-83
- comment-out line 90 (save)

### scripts/preparation/SmokingDefinition13/scripts/3_3_LongitudinalRecord.do
- comment-out line 130 (save)
- comment-out lines 6-10 and replace with:
```
bys patid (date): gen tfupstart=date[1]
gen index_main=tfupstart
gen index_pre=tfupstart
bys patid (date): gen tfupend=date[_N]
drop if date<tfupstart
drop tfupstart  
```

### scripts/preparation/SmokingDefinition13/scripts/3_4_CreateMatrix.do
- comment-out line 7 (use)
- comment-out lines 13-18
- comment-out lines 32-82
- comment-out line 100 (save)


### scripts/preparation/SmokingDefinition13/scripts/4_1_CessationLength.do 
* file not used

### scripts/preparation/SmokingDefinition13/scripts/5_1_AmountSmoked.do 
* file not used

