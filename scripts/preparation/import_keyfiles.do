* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2019-12-16
*************************************
* Name:	import_keyfiles.do
* Creator:	RMJ
* Date:	20191216
* Desc:	Loads txt files and saves as Stata - key ref files used more than once
* Requires: 
* Version History:
*	Date	Reference	Update
*	20191216	import_keyfiles	Create file
*************************************

frames reset
clear

**** ALSO IMPORT THE ALLPATIENT AND ALLPRACTICE FILES AND LINKAGES
** DENOMINATORS
** patient
import delim using "data/raw/Denominators_2019_11/all_patients_NOV2019.txt"
saveold "data/raw/stata/allpatients.dta", replace
clear

** practice
import delim using "data/raw/Denominators_2019_11/allpractices_NOV2019.txt"
saveold "data/raw/stata/allpractices.dta", replace
clear

** linkage eligibility
import delim using "data/raw/set_17_Source_GOLD/linkage_eligibility.txt"
saveold "data/raw/stata/linkageeligibility.dta", replace
clear

*** LOOKUPS
** product
import delim using "data/raw/Lookups_2019_06/product.txt", delim(tab)
format productname-bnfchapter %50s
saveold "data/raw/stata/product.dta", replace
clear

** medical
import delim using "data/raw/Lookups_2019_06/medical.txt", delim(tab)
saveold "data/raw/stata/medical.dta", replace
clear

** common dosages
import delim using "data/raw/Lookups_2019_06/common_dosages.txt", delim(tab)
saveold "data/raw/stata/common_dosages.dta", replace
clear

***
clear
exit
