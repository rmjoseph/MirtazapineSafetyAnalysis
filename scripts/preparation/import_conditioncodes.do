** CREATED 06-Dec-2019 by RMJ at the University of Nottingham
*************************************
* Name:	import_conditioncodes
* Creator:	RMJ
* Date:	20191206
* Desc:	Imports codelists for medical conditions
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20191206	define_conditioncodes	Create file
*	20191217	import_conditioncodes	Use local i as count indicator
*	20200123	import_conditioncodes	Trim whitespace from readcodes
*	20200204	import_conditioncodes	Add depressionsymptoms
*	20200218	import_conditioncodes	Update conditions list to include all
*	20200309	import_conditioncodes	Add depscales
*	20200723	import_conditioncodes	Add extended list of conditions
*************************************

/* NOTES
* Create a single combined file of all the codelists
*/

set more off
frames reset
clear

** LOG
capture log close codeimportlog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/importconditioncodes`date'.txt", text append name(codeimportlog)
**

frame create codes



** Import all the codes
frame change codes
clear

** Local macro matching names of the tabs in the excel codes file that contain
** Read codes for diagnoses
#delimit ;
local conditions "abdompain af aids alcoholmisuse anaemia angina 
appetiteloss asthma anxiety bipolar cancer carehome cerebrovas chf 
copd dementia depression depressionsympt depscale diabetes diab_comp 
dyspnoea eatingdis epilepsy fibromyalgia hemiplegia hospitaladmi huntingtons 
hypertension ibd indigestion insomnia intellectualdisab legulcer
liverdis_mild liverdis_mod mentalhealthservices metastatictumour mi 
migraine mobility ms neuropathicpain obesity palliative pancreatitis 
parkinsons personalitydis pud pvd renal rheumatological schizophrenia 
selfharm sleepapnoea substmisuse vte weightloss";
#delimit cr

di "`conditions'"

** Clear dataset, import the codes for each condition, append to create one long dataset
local i = 0 // counter for if loop

// Open loop for each condition (X)
foreach X of local conditions {
	
	di "****** CONDITION:    `X'"
	
	// clear data in memory
	clear
	
	// increment the counter
	local i=`i'+1
	
	// import the codes for condition X
	import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(`X') firstrow case(lower)
	
	// Drop blank rows if imported
	drop if readcode==""
	
	// Keep only readcode (not the description)
	keep readcode
	
	// Create indicator for that variable, named after condition X
	gen `X' = 1

	// Save as a new dataset if first pass of loop, otherwise append the combined 
	// results from previous pass and save 
	if `i'==1 { 
		save data/clean/conditionscodes.dta, replace
		}	
	else {
		append using data/clean/conditionscodes.dta 
		save data/clean/conditionscodes.dta, replace
		}
	
	// Close loop for condition (X)
	}

	
*** ADDITION 23-jan-2020 trim possible white space from readcodes
replace readcode = strtrim(readcode)
	
*** Some readcodes may be included in multiple lists. Collapse such duplicates,
**  retaining the indicator info
*#delimit ;
*local conditions "af aids alcoholmisuse anaemia angina anxiety bipolar cancer cerebrovas chf copd dementia 
*depression diabetes diab_comp dyspnoea eatingdis epilepsy hemiplegia huntingtons hypertension insomnia 
*intellectualdisab liverdis_mild liverdis_mod metastatictumour mi ms palliative pancreatitis parkinsons 
*pepticulcer personalitydis pud pvd renal rheumatological schizophrenia selfharm vte";
*#delimit cr

// Where readcodes are in more than one list, change each condition indicator to 1 as appropriate
sort readcode
foreach X of local conditions {
	bys readcode (`X'): replace `X'=`X'[1]
	}

// Drop duplicates (duplicates of readcode should now be duplicates in all vars)
duplicates drop


** Link the readcodes to medcodes
// import medical dictonary
frame create medical
frame change medical
clear
use data/raw/stata/medical.dta
keep readcode medcode desc

frame change codes
frlink 1:1 readcode, frame(medical)
keep if medical<. // some readcodes may not match - this is OK, non-Read2 codes were not necessarily removed
frget *, from(medical)

drop medical
frame drop medical


* Tidy file
order medcode readcode desc, first
save data/clean/conditionscodes.dta, replace


clear
capture log close codeimportlog
exit


