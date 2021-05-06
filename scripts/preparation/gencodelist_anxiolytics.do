*************************************
* Name:	gencodelist_anxiolytics.do
* Creator:	RMJ
* Date:	20191104
* Desc:	Creates a list of prodcodes for anxiolytics
* Notes: Base on BNF chapters 4.1.2
* Version History:
*	Date	Reference	Update
*	20191104	gencodelist_statins	Modify statins file for anxiolytics
*	20191113	gencodelist_anxiolytics	Refer to the stringsearch.do file rather than in script
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
local anxiolytic "^040102 /040102"

local catlist "anxiolytic"

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
	stringsearch prodcode anxiolytic `X' "bnfcode" "``X''"
	}

*** MANUAL CHECK OF THE RESULTS
keep if anxiolytic!=""

	
** Keep only the relevant rows and variables of interest
keep prodcode drugsubst anxiolytic

	
** Save and clear
sort drug prodcode
saveold data/codelists/prodcode_gold_anxiolytics.dta, replace
export delimited using data/codelists/prodcode_gold_anxiolytics.csv, replace
clear


exit
