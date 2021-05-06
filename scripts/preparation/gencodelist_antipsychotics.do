*************************************
* Name:	gencodelist_antipsychotics
* Creator:	RMJ
* Date:	20191104
* Desc:	Creates a list of prodcodes for antipsychotics
* Notes: Base on BNF chapters 04020100 and 04020200
* Version History:
*	Date	Reference	Update
*	20191104	gencodelist_statins	Modify statins file for antipsychotics
*	20191113	gencodelist_antipsychotics	Refer to the stringsearch.do file rather than in script
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
local antipsychotic "^040201 /040201 ^040202 /040202"

local catlist "antipsychotic"

******************************************************************

** Now run the program
/* stringsearch needs the following args in this order: 
	id variable (i.e. prodcode - used to merge results with orig data)
	new variable name (the variable holding the search results)
	a label for items in search (a string to label the results)
	"list of fields to search" (list of existing variables)
	"list of search terms" (will all be treated as lowercase)
*/

foreach X of local catlist {
	stringsearch prodcode antipsyc `X' "bnfcode" "``X''"
	}

*** MANUAL CHECK OF THE RESULTS
keep if antipsyc!=""

	
** Keep only the relevant rows and variables of interest
keep prodcode drugsubst antipsyc

	
** Save and clear
sort drugsubst prodcode
saveold data/codelists/prodcode_gold_antipsyc.dta, replace
export delimited using data/codelists/prodcode_gold_antipsyc.csv, replace
clear


exit
