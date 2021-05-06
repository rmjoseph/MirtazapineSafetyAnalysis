*************************************
* Name:	gencodelist_statins
* Creator:	RMJ
* Date:	20191104
* Desc:	Creates a list of prodcodes for statins
* Notes: Restricted this to statins (02120400) rather than other lipid regulators
* Version History:
*	Date	Reference	Update
*	20191104	gencodelist_antidepressants	Modify antidep file for statins
*	20191113	gencodelist_statins	Refer to the stringsearch.do file rather than in script
*************************************

set more off
clear

** Start by defining program to search for specified terms in specified fields
do scripts/quicktools/stringsearch


**********************************************************
********************************************************** START OF DATA PROCESSING

** Open product dictionary (CPRD GOLD)
use prodcode productname drugsubstance bnfcode bnfchapter using "data/raw/stata/product.dta"

** Replace string variables with all lower case (not technically needed as program can handle)
replace productname = lower(productname)
replace drugsubstance = lower(drugsubstance)


*****************************************************************
*** SET UP TERM LIST:
local statin "^021204 /021204"

local atorvastatin "atorvastatin lipitor"
local fluvastatin "fluvastatin lescol"
local pravastatin "pravastatin lipostat"
local rosuvastatin "rosuvastatin crestor"
local simvastatin "simvastatin zocor"

local catlist "statin"
#delim ;
local druglist	"atorvastatin fluvastatin pravastatin rosuvastatin simvastatin";
#delim cr
******************************************************************

** Run program for antidepressant categories and individual drugs
** First test to make sure the macro expands as expected ("" so doesn't treat as varname, double `' to evaluate orig local)
set trace on
foreach X of local druglist {
	di "``X''"
	}
set trace off

** Now run the program
/* stringsearch needs the following args in this order: 
	id variable (i.e. prodcode - used to merge results with orig data)
	new variable name (the variable holding the search results)
	a label for items in search (a string to label the results)
	"list of fields to search" (list of existing variables)
	"list of search terms" (will all be treated as lowercase)
*/

foreach X of local catlist {
	stringsearch prodcode statin `X' "bnfcode" "``X''"
	}

foreach X of local druglist {
	stringsearch prodcode drug `X' "productname drugsubst" "``X''"
	}


	
*** MANUAL CHECK OF THE RESULTS
count if statin!="" & drug!=""
count if statin!="" & drug==""
count if statin=="" & drug!=""

keep if statin!="" | drug !=""	

// NOTE: cerivastatin was withdrawn from the market in 2001 so don't need to include.
	
** Keep only the relevant rows and variables of interest
keep prodcode drugsubst drug
keep if drug!=""
	
** Save and clear
sort drug prodcode
saveold data/codelists/prodcode_gold_statins.dta, replace
export delimited using data/codelists/prodcode_gold_statins.csv, replace
clear


exit
