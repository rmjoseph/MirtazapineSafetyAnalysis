# Use of the DrugPrep algorithm
This analysis uses a published data preparation algorithm to estimate stop dates for antidepressant prescriptions. This algorithm is available via Zenodo.org at the following url: https://doi.org/10.5281/zenodo.793774

Use of the algorithm should be cited:
> Mark Lunt, Stephen Pye, Mohammad Movahedi, & Ruth Costello. (2018, July 17). DrugPrep (STATA) : An algorithm to transform raw CPRD prescriptions data into formatted analysis-ready drug exposure data. (Version v2.0.0). Zenodo. http://doi.org/10.5281/zenodo.1313712

The algorithm is shared via a CC-BY-NC-ND licence (https://creativecommons.org/licenses/by-nc-nd/4.0/).

Some changes were made to the files so they ran for the current analysis - these are detailed below. However, the algorithm must be downloaded and modified separately. If you wish to use the DrugPrep algorithm you should download the original code using the link above. All changes made to individual files are highlighted within the shared files, and are summarised at the end of this file.

The complete algorithm has not been provided as part of this upload - you will need to download it separately and store the scripts according to the DrugPrep folder structure.


# SUMMARY OF CHANGES:

### scripts/preparation/DrugPrep200/scripts/run.do
- renamed run_ad.do
- moved to scripts/preparation
- commented-out line 10
- updated macros lines 12-15
- addition line 12 `args DRUG`
- addition at line 9 describing original scripts and how to access

### scripts/preparation/DrugPrep200/scripts/1_pre_drugprep/1_pre_drugprep.do
- renamed 1_pre_drugprep_ad.do
- moved to scripts/preparation
- largely re-written to adapt to current analysis and new CPRD structure

### scripts/preparation/DrugPrep200/scripts/2_run_drugprep/run_decs.do
- replaced line 31 (use) with:
```
local open = "$datadir" + "pre_drugprep_out.dta"
di "`open'"
use "`open'", clear
```
- replaced line 51 (save) with:
```
local saveas = "$datadir" + "post_drugprep_out.dta"
di "`saveas'"
saveold "`saveas'", replace
```

### scripts/preparation/DrugPrep200/scripts/3_drugprep_scripts/dec0_set_implausible_values.do
- replaced all code with:
```
* RMJ EDIT 09 DEC 2019

gen qty_max = 200
gen qty_min = 0
gen max_rec_ndd = 20
gen min_rec_ndd = 0


exit
```


### scripts/preparation/DrugPrep200/scripts/3_drugprep_scripts/dec9_overlapping_prescriptions.do
- Line 31 replaced with:
```
************* RMJ ADDITION **************
	display "$S_TIME  $S_DATE"
	// Split patients into groups of 500 by creating a new index variable then
	// using this to create a group variable
	
	// New patient index: label first record per patient then use replace
	// to sequentially sum
	bys patid: gen newindex = 1 if _n==1
	replace newindex = sum(newindex)
	
	replace newindex = ceil(newindex/500) // groups of 500 patients
	
	
	
	// Turn this new index variable into a group variable
	*qui sum newindex
	*egen newindex2 = cut(newindex), at(1(1000)`r(max)') icodes // rmj 20191219 boost from 500 to 1000
	*replace newindex = newindex2 + 1 // plus 1 as the first group created is 0
	*drop newindex2
	
	// Final group created is missing - fill in 
	*qui sum newindex
	*di r(max)
	*replace newindex = `r(max)' + 1 if newindex==.
	
	// Loop the tvc_split over the groups of patients created in previous step,
	// as it struggles with large datasets
	capture frame drop newframe
	frame create newframe

	qui sum newindex
	di r(max)
	
	// forvalues as foreach numlist is too long for Stata. Forvalues should be more efficient anyway.
	// open forvalues loop X
	forvalues X = 1/`r(max)' {
		
		di `X'

		frame change default

		// For each of the patient subgroups, copy into a new frame
		capture frame drop tempframe	
		frame put if newindex==`X', into(tempframe)
		drop if newindex==`X' // addition 20 dec 2019 to reduce amount of memory used
		frame change tempframe
		
		// tvc_split
		tvc_split start real_stop, common(patid prodcode) 
		
		// save temporary file and append into the newframe
		tempfile patsplit
		save `patsplit', replace
		frame change newframe
		append using `patsplit'
		
		// reset the loop
		frame change default
		frame drop tempframe
		
		} 
	
	// Copy the newly created split dataset from newframe into the default frame
	frame change newframe
	frame drop default
	frame rename newframe default
	*frame copy newframe default
	*frame change default
	*frame drop newframe
	
	drop newindex
	display "$S_TIME  $S_DATE"
	************************
```
















