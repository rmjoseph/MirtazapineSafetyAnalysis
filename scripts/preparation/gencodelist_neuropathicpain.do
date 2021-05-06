**CREATED 2020-07-01 by RMJ at the University of Nottingham
*************************************
* Name:	gencodelist_neuropathicpain.do
* Creator:	RMJ
* Date:	20200701
* Desc:	Creates a list of Readcodes for neuropathic pain
* Notes: 
* Version History:
*	Date	Reference	Update
*	20200701	gencodelist_neuropathicpain	First version created
*	20200707	gencodelist_neuropathicpain	Terms updated and 3 lists separated
*************************************

frames reset
clear
use data/raw/stata/medical.dta

replace desc = lower(desc)
sort readcode

gen keep = .
gen not = .

**** NEUROPATHIC PAIN
frame put *, into(np)
frame change np

** Search based on following terms
local terms  `" "neuralg" "pain" "sciatica" "douloureux" "reflex sympathetic dystrophy" "radiculopathy" "meralgia" "neuritis" "neuropath" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(desc,"`X'")==1
	}

** Remove definite errors	
local terms "paint spain papain"
foreach X of local terms {
	replace keep = . if regexm(desc,"`X'")==1
	}

** Remove admin/treatment codes
local terms "questionn refer manag control relie prevent minim letter scale score training vaccination screen review tool rehab text assess diary clinic"
foreach X of local terms {
	replace keep = . if regexm(desc,"`X'")==1
	}

	
** Refine
keep if keep==1
replace keep=.	

** More specific terms
local terms  `" "neuralg" "sciatica" "douloureux" "reflex sympathetic dystrophy" "lumbar" "low back" "lumbosacral" "meralgia" "stroke" "operat" "regional pain syn" "cancer" "metast" "chemo" "surg" "phantom" "neuropathic pain" "painful diabetic neuropathy" "prosthe" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(desc,"`X'")==1
	}

** Exclusions
** search terms
replace not=.
local terms  `" "personality" "without pain" "temporomandibular" "scar" "low back pain" "lumbar pain" "pain in lumbar spine" "acute back pain - lumbar" "lumbosacral neuritis" "abd" "' 
foreach X of local terms {	
	replace not = 1 if regexm(desc,"`X'")==1
	}
sort keep not read


** for code review
gen drop=.
local terms  `" "^196" "^197" "^19E" "^1A5" "^25C" "Ll6y500" "^R0[7 8 9]"  "^Ryu1" "^182" "^1ABD" "^J574" "^K2[7 8]"  "^L4635" "^Z[2 7 L]" "' 
foreach X of local terms {	
	replace drop = 1 if regexm(read,"`X'")==1
	}
sort keep not read

sort drop read

local terms  `" "1A53.12" "25C..13" "' 
foreach X of local terms {	
	replace drop = . if regexm(read,"`X'")==1
	}

drop if drop==1
replace not=0 if not==.
sort keep not readcode

keep if keep==1 & not==0

	
	


**** FIBROMYALGIA
frame change default
capture frame drop fb
frame put *, into(fb)
frame change fb

** Search based on following terms
local terms  `" "fibromyalgia" "pain" "myalgia" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(desc,"`X'")==1
	}

	
** Remove definite errors	
local terms "paint spain papain"
foreach X of local terms {
	replace keep = . if regexm(desc,"`X'")==1
	}

replace not = 1 if regexm(readcode,"^19")==1	// git pain
replace not = 1 if regexm(readcode,"^1A")==1	// genitourinary pain	
replace not = 1 if regexm(readcode,"^R065")==1	// chest pain	
replace not = 1 if regexm(readcode,"^R07")==1	// gas/GI pain
replace not = 1 if regexm(readcode,"^R090")==1	// abdominal pain	

bro if keep==1 & not!=1


gen maybe = .
replace maybe = 1 if regexm(readcode,"^1DC8")==1	// generalised pain [sympt]
replace maybe = 1 if regexm(readcode,"N239\.00")==1	// fibromyalgia
replace maybe = 1 if regexm(readcode,"N248\.00")==1	// fibromyalgia
replace maybe = 1 if regexm(readcode,"R00z200")==1	// pain, generalized
replace maybe = 1 if regexm(readcode,"R00z211")==1	// general aches and pains
	
	
sort keep not read
keep if keep==1
bro if maybe==1



	
**** ABDOMINAL PAIN / IBS (IBS FROM CALIBER)
frame change default
capture frame drop ibs
frame put *, into(ibs)
frame change ibs

** Search based on following terms
local terms  `" "pain" "irritable bowel" "spastic colon" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(desc,"`X'")==1
	}

keep if keep==1


** Reset keep and refine search
replace keep=.

** based on the following terms
local terms  `" "abd" "git" "irritable bowel" "spastic colon" "' 
foreach X of local terms {	
	replace keep = 1 if regexm(desc,"`X'")==1
	}
	
** & based on the following readcodes
local terms "^196 ^197 ^R090 ^25C"
foreach X of local terms {	
	replace keep = 1 if regexm(readcode,"`X'")==1
	}

sort keep readcode
keep if keep==1
sort readcode

** Exclusions
local terms  `" "no " "pregnan" "gas " "education" "bleeding" "manag" "' 
foreach X of local terms {	
	replace not = 1 if regexm(desc,"`X'")==1
	}
sort not read

replace not=0 if not!=1
sort keep not read

keep if not!=1



