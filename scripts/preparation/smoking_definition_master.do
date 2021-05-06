* Copyright (c) Arthritis Research UK Centre for Epidemiology, University of Manchester (2016-2018)
** RMJ at University of Nottingham edited to run on mirtazapine safety project; remove all the save steps and use frames instead.

/* NOTE - this is a modified version of the software SmokingDefinition v1.3 available from Zenodo.org.
* The original code is available here: https://doi.org/10.5281/zenodo.793392
* The original code is shared under a CC-BY-NC-ND licence (https://creativecommons.org/licenses/by-nc-nd/4.0/).
* The changes are highlighted in the individual files and here:
*	scripts/preparation/SmokingDefinition13/README.md
*/

** macros
global	basedir	"scripts/preparation/SmokingDefinition13"
global	datadir	"data/raw/stata"	

** Log
local date: display %dCYND date("`c(current_date)'", "DMY")
di `date'
local logname: display "SmokingDefinition_"`date'
di "`logname'"

capture log close smoking
log using "logs/`logname'.log", append name(smoking)


** Scripts
* generate readcode list, smoking status
frame create smoking_readcodes	// NEW 
frame change smoking_readcodes	// NEW 
do $basedir/scripts/1_1_ImportReadcodes.do

* generate prodcode list, smoking cessation therapies
frame create smoking_therapy	// NEW 
frame change smoking_therapy	// NEW 
do $basedir/scripts/1_2_ProductCodelist.do

* Extract smoking data from additional files
frame create ad_prep	// NEW 
frame change ad_prep	// NEW 
do $basedir/scripts/2_1_AdditionalFile.do

* NEW - RMJ 20200129 PICK ONE ADDITIONAL PER DAY (do not have adid in clinical file so cannot link later)
do $basedir/scripts/2_1_1_AdditionalDays.do

* Extract smoking therapy use
frame create therapy_prep	// NEW 
frame change therapy_prep	// NEW 
do $basedir/scripts/2_2_SmokingInTherapy.do


* Extract all diagnostic codes
frame create medcodes_prep	// NEW 
frame change medcodes_prep	// NEW 
do $basedir/scripts/2_3_SmokingRecordMedcode.do

* Extract enttype 6 from clinical
*do $basedir/scripts/2_4_SmokingEnttype6.do // RMJ removed for mirtazapine 2020-1-24

* Combine all datasets
frame change medcodes_prep	// NEW 
frame put *, into(smokefiles_combined)	// NEW 
frame change smokefiles_combined	// NEW 
do $basedir/scripts/2_5_CombineDatasources.do

* Specify single smoking status per episode
frame change smokefiles_combined	// NEW 
frame put *, into(smoking_perepisode)	// NEW 
frame change smoking_perepisode	// NEW 
do $basedir/scripts/3_1_SmokingEpisodes.do


* Specify single smoking status per day
do $basedir/scripts/3_2_SmokingDays.do


* Correct longitudinal statuses
do $basedir/scripts/3_3_LongitudinalRecord.do


* Collapse to Matrix
do $basedir/scripts/3_4_CreateMatrix.do


* Smoking cessation length
*do $basedir/scripts/4_1_CessationLength.do // RMJ removed for mirtazapine 2020-1-24

* Amount smoked
*do $basedir/scripts/5_1_AmountSmoked.do // RMJ removed for mirtazapine 2020-1-24


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
