*************************************
* Name:	expandShortReadCodes
* Creator:	RMJ, University of Nottingham
* Date:	20190912
* Desc:	Expands short-form readcodes from a new codelist into full codes. Requires the codelist to be pasted into the edit window.
* NOTE - requires stata v16
* Version History:
*	Date	Reference	Update
*	20190912	expandShortReadCodes	Create file
*	20200204	expandShortReadCodes	Reorder file and change to frames rather than merge
*************************************
clear
frame reset
set more off

** Open the medcodes dictionary
use "data\raw\stata\medical.dta"

** Check for leading/trailing spaces
replace readcode = strtrim(readcode)

** Create new variable containing short-form Read code
rename readcode read2
gen readcode = substr(read,1,5)

duplicates drop



** Use the new frames functionality to avoid creating multiple files
frame create newlist
frame change newlist

** Paste the short code list into the edit window
gen readcode = ""
edit // paste in the new codes

** Check for leading/trailing spaces
replace readcode = strtrim(readcode)

** Tempsave this dataset
*tempfile newlist
*save "`newlist'"


** Go back to original data frame
frame change default

** Merge with the codelist
frlink m:1 readcode, frame(newlist)
frget *,from(newlist)
keep if newlist < .
drop newlist
*merge m:1 readcode using "`newlist'"
*keep if _merge==3
*drop _merge

** Tidy
keep medcode read2 desc
rename read2 readcode
frame drop newlist

/* Save or export as required
saveold PATH/NAME, replace
export delimited using PATH/NAME.csv, replace
*/

clear
exit
