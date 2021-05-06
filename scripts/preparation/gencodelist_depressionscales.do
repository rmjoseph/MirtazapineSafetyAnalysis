**CREATED 2020-03-09 by RMJ at the University of Nottingham
*************************************
* Name:	gencodelist_depressionscales.do
* Creator:	RMJ
* Date:	20200309
* Desc:	Creates a list of Readcodes for depression (severity) scales
* Notes: 
* Version History:
*	Date	Reference	Update
*	20200309	gencodelist_depressionscales	First version created
*************************************

frames reset
clear
use data/raw/stata/medical.dta

replace desc = lower(desc)
sort readcode

gen depscale = .
gen not = .
gen scale = .

local terms `" "geriatric depression" "gds" "hospital anxiety and depression" "had" "phq" "patient health questionnaire" "'
foreach X of local terms {	
	replace depscale = 1 if regexm(desc,"`X'")==1
	}


local terms "lymphaden methad chad  sulphadi shadow partner haddock declined"
foreach X of local terms {
	replace not = 1 if regexm(desc,"`X'")==1
	}

	
local terms "score scale level"
foreach X of local terms {
	replace scale = 1 if regexm(desc,"`X'")==1
	}

	
gen keep = 1 if depscale==1 & not!=1 & scale==1
drop depscale not scale

keep if keep==1

list readcode desc, clean noobs

clear

