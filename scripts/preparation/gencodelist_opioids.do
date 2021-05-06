*************************************
* Name:	gencodelist_opioids.do
* Creator:	RMJ
* Date:	20191209
* Desc:	Creates a list of prodcodes for opioids
* Notes: Base on BNF chapters 4.7.2
* Version History:
*	Date	Reference	Update
*	20191209	gencodelist_opioids.do	First version
*	20200713	gencodelist_opioids.do	Expand to include those not coded a 4.7.2
*************************************

set more off
clear

use "data\raw\stata\product.dta" 
replace drugsubst = lower(drugsubst)
replace productname = lower(productname)

gen opioid=(regexm(bnfcode,"040702")==1)
*gen compound=regexm(bnfcode,"040701")
*gen nsaid=regexm(bnfcode,"100101")
*gen mig=regexm(bnfcode,"040704")

local 	codeine	"	codeine	"
local 	morphine	"	morphine	"
local 	alfentanil	"	alfentanil	"
local 	buprenorphine	"	buprenorphine	"
local 	dextromoramide	"	dextromoramide	"
local 	dextropropoxyphene	"	dextropropoxyphene	"
local 	diamorphine	"	diamorphine	"
local 	dihydrocodeine	"	dihydrocodeine	"
local 	dipipanone	"	dipipanone	"
local 	ethylmorphine	"	ethylmorphine	"
local 	fentanyl	"	fentanyl	"
local 	hydromorphone	"	hydromorphone	"
local 	levorphanol	"	levorphanol	"
local 	meptazinol	"	meptazinol	"
local 	methadone	"	methadone	"
local 	nalbupine	"	nalbupine	"
local 	naloxone	"	naloxone	"
local 	oxycodone	"	oxycodone	"
local 	papaveretum	"	papaveretum	"
local 	papaveretum	"	papaveretum	"
local 	pentazocine	"	pentazocine	"
local 	pethidine	"	pethidine	"
local 	phenazocine	"	phenazocine	"
local 	tapentadol	"	tapentadol	"
local 	tramadol	"	tramadol	"
				

#delim ;
local druglist	"codeine
morphine
alfentanil
buprenorphine
dextromoramide
dextropropoxyphene
diamorphine
dihydrocodeine
dipipanone
ethylmorphine
fentanyl
hydromorphone
levorphanol
meptazinol
methadone
nalbupine
naloxone
oxycodone
papaveretum
papaveretum
pentazocine
pethidine
phenazocine
tapentadol
tramadol
";
#delim cr

foreach X of local druglist {
	replace opioid=1 if regexm(productn,"`X'")==1 | regexm(drugsubst,"`X'")==1
	}
sort bnfcode

keep if opioid==1
keep if regexm(bnfcode,"00000000")==1 | regexm(bnfcode,"^040701")==1 | regexm(bnfcode,"^040702")==1

*drop if mig==1 | comp==1 | nsaid==1

sort drugsubst prodcode
bro prodcode drugsubst

clear
exit
