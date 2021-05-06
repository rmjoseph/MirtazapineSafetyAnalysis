* CREATED BY RMJ AT THE UNIVERSITY OF NOTTINGHAM 2020-01-29
*************************************
* Name:	antidepstrength.do
* Creator:	RMJ
* Date:	20200129
* Desc: Manually extract strength info for each of the antideps of interest
* Requires: Stata 16 (Frames function)
* Version History:
*	Date	Reference	Update
*	20191212	antidepstrength	Create file
*************************************

set more off
frames reset
clear

** LOAD ANTIDEPS CODES
frame create codes
frame change codes
clear
use data/clean/drugcodes.dta, replace
keep if antidep==1
keep prodcode antideptype antidepdrug

** LOAD PRODUCT DICTIONARY
frame create product
frame change product
clear
use data/raw/stata/product.dta
keep prodcode productname drugsubstance strength formulation route

** COMBINE ANTIDEP CODES WITH PRODUCT DICTIONARY
frlink 1:1 prodcode, frame(codes)
keep if codes<.
frget *, from(codes)
drop codes

** GENERATE NEW VARIABLES (STRENGTH, UNITS, TYPE); EXTRACT INFO BY SEARCHING THE STRINGS
gen newstrength = .
gen units = ""

gen complex = (regexm(strength,"/")==1 | regexm(strength,"\+")==1)

// simple tablets
replace units = "mg" if complex==0 & regexm(strength,"mg")==1

local numbers 1 2 3 4 5 10 15 20 25 30 37.5 40 45 50 60 70 75 100 150 200 225 300 500
foreach X of local numbers {
	replace newstrength = `X' if complex==0 & regexm(strength,"`X'mg")==1
	}

// tablets in micrograms
replace newstrength = 0.5 if complex==0 & regexm(strength,"500microgram")==1
replace units = "mg" if complex==0 & regexm(strength,"500microgram")==1

// simple solutions
replace units = "mg/ml" if regexm(strength,"mg/ml")==1 | regexm(strength,"mg/1ml")==1

local numbers 1 2 4 5 2.5 7.5 10 12 12.5 14 15 20 25 30 40 50 75 100 200

foreach X of local numbers {
	replace newstrength = `X' if regexm(strength,"`X'mg/")==1 & units=="mg/ml"
	}


// solutions in micrograms or other units
replace newstrength = 0.5 if regexm(strength,"500microgram/1ml")==1
replace units = "mg/ml" if regexm(strength,"500microgram/1ml")==1

replace newstrength = 0.4 if regexm(strength,"400microgram/1ml")==1
replace units = "mg/ml" if regexm(strength,"400microgram/1ml")==1

replace newstrength = 2 if regexm(strength,"10mg/5ml")==1
replace units = "mg/ml" if regexm(strength,"10mg/5ml")==1

replace newstrength = 5 if regexm(strength,"25mg/5ml")==1
replace units = "mg/ml" if regexm(strength,"25mg/5ml")==1

replace newstrength = 15 if regexm(strength,"75mg/5ml")==1
replace units = "mg/ml" if regexm(strength,"75mg/5ml")==1

// creams
replace newstrength = 50 if regexm(strength,"50mg/1gram")==1
replace units = "mg/g" if regexm(strength,"50mg/1gram")==1

// compound tablets
replace newstrength = 10 if prodcode==16323 | prodcode==3490 | prodcode==1453 | prodcode==38827 | prodcode==2936 | prodcode==7780 | prodcode==20571 | prodcode==24890
replace newstrength = 12.5 if prodcode==21081
replace newstrength = 25 if prodcode==18342 | prodcode==6894 | prodcode==1208 | prodcode==595
replace newstrength = 30 if prodcode==14578 | prodcode==8493
replace units = "mg" if regexm(strength,"\+")==1

// label type of drug
replace route=lower(route)
replace formulation=lower(formulation)
gen type = ""
replace type = "pill" if units=="mg"
replace type = "compound pill" if regexm(strength,"\+")==1
replace type = "cream" if units=="mg/g"
replace type = "oral sol" if units=="mg/ml" & regexm(route,"oral")==1
replace type = "oral drops" if units=="mg/ml" & regexm(formulation,"oral drops")==1
replace type = "injection" if units=="mg/ml" & regexm(formulation,"inject")==1

// UNKNOWN STRENGTH
replace productn = lower(productn)
replace drugsubst = lower(drugsubst)

replace type = "pill" if strength=="" & (regexm(productn,"tab")==1 | regexm(productn,"cap")==1 )
replace type = "injection" if strength=="" & (regexm(productn,"inj")==1 )
replace type = "oral sol" if strength=="" & (regexm(productn,"oral s")==1 | regexm(productn,"oral liq")==1)

local numbers 10 15 25 30 50 60 75 100 200 300
foreach X of local numbers {
	replace newstre=`X' if strength=="" & type=="pill" & regexm(productn,"`X' mg")==1
	}

replace units = "mg" if strength=="" & type=="pill"

replace newstrength = 40 if prodcode==65771
replace units = "mg/ml" if prodcode==65771

*replace newstrength = 5 if prodcode==8250
*replace units = "mg/ml" if prodcode==8250

replace newstrength = 30 if prodcode==74753



// tidy & save
keep prodcode strength newstrength units type
sort prodcode
saveold data/clean/drugstrengths, replace

frames reset
clear
exit
