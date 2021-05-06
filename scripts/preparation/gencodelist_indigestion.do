**CREATED 2020-07-13 by RMJ at the University of Nottingham
*************************************
* Name:	gencodelist_indigestion.do
* Creator:	RMJ
* Date:	20200713
* Desc:	Creates a list of Readcodes for indigestion
* Notes: 
* Version History:
*	Date	Reference	Update
*	20200713	gencodelist_indigestion	First version created
*************************************

frames reset
clear
use data/raw/stata/medical.dta

replace desc = lower(desc)
sort readcode

gen keep = .
gen not = .

** Search based on following terms
local terms  `" "indigestion" "dyspepsia" "eructation" "belch" "flatulence" "bloating" "heartburn" "reflux" "gerd" "nausea" "vomit" "emesis" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(desc,"`X'")==1
	}

** higher-level read codes
local terms  `" "^19[5 8 9 A B]" "^J16" "^R07" "^Eu453" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(read,"`X'")==1
	}
sort keep read

** Exclusions
local terms  `" "^R07[6 7 8 9 A z]" "^K" "^L13" "^Lyu" "^PD47" "^Q" "^4A" "^760" "^H47" "' 
foreach X of local terms {	
	replace not = 1 if regexm(read,"`X'")==1
	}
sort keep read


replace not=0 if not==.
sort keep not read
bro if keep==1

