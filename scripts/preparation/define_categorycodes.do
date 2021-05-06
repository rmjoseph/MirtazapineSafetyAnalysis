** CREATED 23-Jan-20 by RMJ at the University of Nottingham
*************************************
* Name:	define_categorycodes
* Creator:	RMJ
* Date:	20200123
* Desc:	Imports codelists for variables with categories
* Requires: Stata 16 for frames function
* Version History:
*	Date	Reference	Update
*	20200123	define_categorycodes	Create file
*************************************

/* NOTES
* Create a single combined file of all the codelists
*/

set more off
frames reset
clear

// SMOKING STATUS
import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(smoking) firstrow case(lower)

label def smokstat 1 "Never" 2 "Not Current" 3 "Former" 4 "Current" 5 "Ever"
label values smokingst smokstat

keep readcode smoking
keep if readcode !=""

// ALCOHOL STATUS
frame create toappend
frame change toappend

import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(alcohol) firstrow case(lower)

encode category, gen(alcoholintake)
keep readcode alcoholintake
keep if readcode !=""

recode alcoholintake (1=2) (2=5) (3=4) (4=1) (5=3)

label define alcoholintake ///
           2 "former" ///
           5 "heavy" ///
           4 "moderate" ///
           1 "nondrinker" ///
           3 "occasional", replace

label values alcoholintake alcoholintake

tempfile tolink
save "`tolink'", replace

frame change default
append using "`tolink'"


// ETHNICITY
frame change toappend
clear

import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(ethnicity) firstrow case(lower)

encode category, gen(ethnicity)
keep if readcode !=""

keep readcode ethnicity

tempfile tolink
save "`tolink'", replace

frame change default
append using "`tolink'"



// DEPRESSION SEVERITY
frame change toappend
clear

import excel data/codelists/Appendix1_mirtaz_codelists.xlsx, sheet(depression) firstrow case(lower)

keep if readcode!=""

encode severity, gen(depsev)
keep if depsev!=.
keep readcode depsev

tempfile tolink
save "`tolink'", replace
frame change default
append using "`tolink'"



// link with medcodes
duplicates report readcode
replace readcode = strtrim(readcode)
merge 1:1 readcode using data/raw/stata/medical.dta

keep if _merge==3
drop _merge




* Tidy file
order medcode, first
drop desc readcode
save data/clean/categorycodes.dta, replace

frames reset
exit

