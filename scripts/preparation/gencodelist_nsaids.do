*************************************
* Name:	gencodelist_nsaids.do
* Creator:	RMJ
* Date:	20191104
* Desc:	Creates a list of prodcodes for nsaids
* Notes: Base on BNF chapters 4.1.1
* Version History:
*	Date	Reference	Update
*	20191104	gencodelist_statins	Modify statins file for nsaids
*	20191113	gencodelist_nsaids	Refer to the stringsearch.do file rather than in script
*	20200713	gencodelist_nsaids	SUPERCEDED BY gencodelist_painkillers.do
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
local nsaids "^100101 /100101"

local catlist "nsaids"

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
	stringsearch prodcode nsaids `X' "bnfcode" "``X''"
	}

*** MANUAL CHECK OF THE RESULTS
keep if nsaids!=""

	
** Keep only the relevant rows and variables of interest
keep prodcode drugsubst nsaids

	
** Save and clear
sort drug prodcode
saveold data/codelists/prodcode_gold_nsaids.dta, replace
export delimited using data/codelists/prodcode_gold_nsaids.csv, replace
clear


exit
