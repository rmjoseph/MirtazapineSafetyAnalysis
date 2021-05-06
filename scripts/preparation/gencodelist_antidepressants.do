*************************************
* Name:	gencodelist_antidepressants
* Creator:	RMJ
* Date:	20190911
* Desc:	Creates a list of prodcodes for grouped antideps and specific drugs
* Notes: BEWARE OF OVERLAPPING SEARCH TERMS, e.g. CITALOPRAM AND ESCITALOPRAM
* Version History:
*	Date	Reference	Update
*	20190911	gencodelist_mirtazapine	Expand prev code for multiple categories
*	20190911	gencodelist_antidepressants	Add the code for mirtazapine into this - one file
*	20190911	gencodelist_antidepressants	Change to program style - easy to add new drugs
*	20191113	gencodelist_antidepressants	Refer to the stringsearch.do file rather than in script
*	20200206	gencodelist_antidepressants	Fix miscoding of nefazodone as SSRI
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
local ssri "0403030"
local tca "0403010"
local maoi "0403020"
local otherAntidep "0403040"

local fluoxetine "fluoxetine prozac serafem"
local citalopram "citalopram cipramil celexa"
local escitalopram "escitalopram cipralex lexapro"
local sertraline "sertraline lustral zoloft"
local paroxetine "paroxetine seroxat paxil"
local mirtazapine "mirtazapin mepirzapine 6-azamianserin org-3770 remeron zispin"
local trazodone "trazodone molipaxin"
local venlafaxine "venlafaxine effexor"
local duloxetine "duloxetine cymbalta"

// see file "ListOfAntidepressants.txt"
local amitriptyline "amitriptyline domical elavil tryptizol triptafen"
local amoxapine "amoxapine asendis"
local butriptyline "butriptyline evadyne evadene"
local clomipramine "clomipramine anafranil"
local desipramine "desipramine pertofran"
local dosulepin "dosulepin prepadine dothapax prothiaden thaden"
local doxepin "doxepin sinepin sinequan"
local imipramine "imipramine pramanil tofranil"
local iprindole "iprindole prondol"
local lofepramine "lofepramine feprapax gamanil lomont"
local mianserin "mianserin bolvidon norval"
local nortriptiline "nortriptyline aventyl allegron"
local protriptyline "protriptyline concordin"
local trimipramine "trimipramine surmontil"
local viloxazine "viloxazine vivalan"
local agomelatin "agomelatin valdoxan"
local tryptophan "tryptophan optimax pacitron"
local flupentixol "flupentixol fluanxol depixol"
local nefazodone "nefazodone"
local reboxetine "reboxetine edronax"
local vortioxetine "vortioxetine brintellix"
local iproniazide "iproniazide marsilid"
local isocarboxazid "isocarboxazid marplan"
local moclobemide "moclobemide manerix"
local phenelzine "phenelzine nardil"
local tranylcypromine "tranylcypromine parnate parstelin"
local fluvoxamine "fluvoxamine faverin"
local nefazodone "nefazodone dutonin"

local catlist "ssri tca maoi otherAntidep"
#delim ;
local druglist	"fluoxetine citalopram escitalopram sertraline paroxetine 
				mirtazapine trazodone venlafaxine duloxetine
				amitriptyline amoxapine butriptyline clomipramine desipramine 
				dosulepin doxepin imipramine iprindole lofepramine mianserin 
				nortriptiline protriptyline trimipramine viloxazine agomelatin 
				tryptophan flupentixol nefazodone reboxetine vortioxetine 
				iproniazide isocarboxazid moclobemide phenelzine 
				tranylcypromine fluvoxamine nefazodone";
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
	stringsearch prodcode antideptype `X' "bnfcode" "``X''"
	}
	
foreach X of local druglist {
	stringsearch prodcode drug `X' "productname drugsubst" "``X''"
	}


	
** Some of the listed drugs may be included in different bnf chapters, or may
** have unknown bnf chapter. Assume these are ok (still represent prescribing 
** of that drug...) APART FROM tryptophan, which is included in dietary supplement
** packs.
replace drug = "" if drug=="tryptophan" & antideptype==""

** fill in missing antideptype
replace antideptype = "tca" if antideptype=="" & (drug=="amitriptyline"|drug=="amoxapine"|drug=="clomipramine"|drug=="dosulepin"|drug=="doxepin"|drug=="imipramine"|drug=="lofepramine"|drug=="mianserin"|drug=="nortriptiline"|drug=="protriptyline"|drug=="trimipramine"|drug=="trazodone")
replace antideptype = "otherAntidep" if antideptype=="" & (drug=="duloxetine"|drug=="flupentixol"|drug=="mirtazapine"|drug=="nefazodone"|drug=="venlafaxine")
replace antideptype = "ssri" if antideptype=="" & (drug=="fluvoxamine")
replace antideptype = "maoi" if antideptype=="" & (drug=="iproniazide")

*** 2020-02-06 spotted error: some rows nefazodone coded as SSRI. Fix.
replace antideptype = "otherAntidep" if drug=="nefazodone"


** Keep only the relevant rows and variables of interest
keep prodcode drugsubst antideptype drug
keep if antideptype!="" | drug!=""
	
** Save and clear
sort antideptype drug prodcode
saveold data/codelists/prodcode_gold_antideps.dta, replace
export delimited using data/codelists/prodcode_gold_antideps.csv, replace
clear


exit
