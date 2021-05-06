**CREATED 2020-07-13 by RMJ at the University of Nottingham
*************************************
* Name:	gencodelist_painkillers
* Creator:	RMJ
* Date:	20200713
* Desc:	Creates a list of prodcodes for grouped analgesics and nsaids
* Notes: BEWARE OF OVERLAPPING SEARCH TERMS, e.g. CITALOPRAM AND ESCITALOPRAM
* Version History:
*	Date	Reference	Update
*	20200213	gencodelist_antidepressants	Adapt for painkillers
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
local analgesic "^040701"
local nsaid "^100101"

local aspirin "aspirin resprin caprin co-codaprin migramax" 
local paracetamol "paracetamol panadol disprol calpol medinol alvedon perfalgan co-codamol paracodol codipar kapake medocodene zapain solpadol tylex co-dydramol remedeine midrid tramacet migraleve paramax"
local nefopam "nefopam acupan"

local aceclofenac "aceclofenac preservex"
local acemetacin "acemetacin emflex"
local celecoxib "celecoxib celebrex"
local diclofenac "diclofenac voltarol defenac dicloflex diclozip fenactol flamrase flamatak flexotard rheumatac rhumalgan slofenac volsaid econac dyloject diclomax motifene dexomon arthrotec"
local etodolac "etodolac eccoxolac etopan lodine"
local etoricoxib "etoricoxib arcoxia"
local fenoprofen "fenoprofen fenopron"
local flurbiprofen "flurbiprofen froben"
local ibuprofen "ibuprofen arthrofen ebufac rimafen calprofen feverfen nurofen orbifen brufen fenbin"
local indometacin "indometacin indomethacin indolar pardelprin"
local ketoprofen "ketoprofen orudis oruvail ketocid ketovail tiloket axorid"
local mefenamic "mefenamic ponstan"
local meloxicam "meloxicam"
local nabumetone "nabumetone relifex"
local naproxen "naproxen naprosyn vimovo napratec"
local piroxicam "piroxicam brexidol feldene"
local sulindac "sulindac"
local tenoxicam "tenoxicam mobiflex"
local tiaprofenic "tiaprofenic surgam" 

local dexibuprofen "dexibuprofen seractil"
local dexketoprofen "dexketoprofen keral"


local catlist "analgesic nsaid"
#delim ;
local druglist	"aspirin paracetamol nefopam
 aceclofenac acemetacin celecoxib diclofenac etodolac etoricoxib fenoprofen
 flurbiprofen ibuprofen indometacin ketoprofen mefanamic meloxicam nabumetone
 naproxen piroxicam sulindac tenoxicam tiaprofenic dexibuprofen dexketoprofen
";
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
stringsearch prodcode analgesic analgesic "bnfcode" "04070100"
stringsearch prodcode nsaid nsaid "bnfcode" "10010100"
	
foreach X of local druglist {
	stringsearch prodcode drug `X' "productname drugsubst" "``X''"
	}

replace analgesic="" if drugsubst=="ibuprofen lysine"
replace analgesic="" if drugsubst=="ibuprofen sodium dihydrate"
replace analgesic="" if drugsubst=="naproxen"
replace analgesic="" if drugsubst=="naproxen sodium"


keep nsaid analgesic drugsubst prodcode
keep if nsaid!="" | analgesic!=""
	

saveold data/codelists/prodcode_gold_painkillers.dta, replace
export delimited using data/codelists/prodcode_gold_painkillers.csv, replace
clear



exit
