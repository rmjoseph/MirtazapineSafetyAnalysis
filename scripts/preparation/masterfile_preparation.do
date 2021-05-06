*************************************
* Name:	masterfile_preparation
* Creator:	RMJ
* Date:	20190606
* Desc:	Sets working directory and runs data prep in required order
* Version History:
*	Date	Reference	Update
*	20190606	masterfile_preparation	Create file
*************************************

** Working directory must have the following structure:
*	data/clean
*	data/codelists
*	data/raw/stata
*	data/raw/*FURTHER DIRECTORIES AS REQUIRED*
*	scripts/preparation
*	scripts/analysis
*	scripts/quicktools


/* list of quick tools and other programs needed
expandShortReadCodes.do
stringsearch.do // defines stringsearch programe
scripts/preparation/CalcAvgDose.do
*/


clear
set more off
frames reset

** Set working directory 
capture cd "... path to /mirtazapine "
pwd

** LOG
capture log close masterlog
local date: display %dCYND date("`c(current_date)'", "DMY")
log using "logs/master_preparation_`date'.txt", text append name(masterlog)


***** STAGES:
**************** Convert some of the key txt files to stata files once at the start 
** (avoid doing all to avoid using excessive amounts of space)
do scripts/preparation/import_keyfiles.do


/**************** Preparatory work for protocol & data extraction
do scripts/preparation/gencodelist_antidepressants
do scripts/preparation/gencodelist_antipsychotics
do scripts/preparation/gencodelist_anxiolytics
do scripts/preparation/gencodelist_hypnotics
*do scripts/preparation/gencodelist_nsaids
do scripts/preparation/gencodelist_statins
do scripts/preparation/gencodelist_opioids
do scripts/preparation/linkage_eligibility
do scripts/preparation/categorise_icd10.do
do scripts/preparation/SmokingDefinition13/scripts/1_2_ProductCodelist.do // added 2020-01-24 code from SmokingDefinition v1.3
do scripts/preparation/gencodelist_depressionscales
do scripts/preparation/gencodelist_painkillers

do scripts/preparation/gencodelist_indigestion
do scripts/preparation/gencodelist_neuropathicpain
*/


**************** Extract data of interest from CPRD files
do scripts/preparation/cohort_eligibility.do // gets all the dates about patient followup

do scripts/preparation/import_conditioncodes.do // imports all the medical condition code lists to create one lookup
do scripts/preparation/define_categorycodes.do // import codelists containing categories (smoking alcohol ethnicity depression(severity))
do scripts/preparation/import_drugcodes.do // imports all the medication code lists to create one lookup

display "$S_TIME  $S_DATE"
do scripts/preparation/define_conditiondates_v2.do // combines the clinical codes with the medical data to find first event for each condition plus all events for depression
display "$S_TIME  $S_DATE"

do scripts/preparation/extract_additionaldata.do // Extract records with enttypes of interest from additional file

do scripts/preparation/define_prescriptionevents.do // combines the drug codes with the therapy data and creates new datasets

do scripts/preparation/extract_testresults.do // Extract records with depression scale test results



**************** Define antidepressant exposure history
do scripts/preparation/antidepstrength.do	// manually extracts strength info for each drug in code list

*define_antidepsequence // creates vars for first, second, and third antidep dates etc
do scripts/preparation/1_pre_drugprep_ad.do // drug prep pre-processing for antideps

forvalues DRUG = 1/35 {
	display "$S_TIME  $S_DATE"
	cd "... path to /mirtazapine"
	do scripts/preparation/run_ad.do `DRUG'	// drug prep for antideps
	// 2020-02-05 temporarily changed file locations (remove change)
	// 2020-02-05 set to 9b not 9a
	display "$S_TIME  $S_DATE"
	}

cd "... path to /mirtazapine"

do scripts/preparation/adinjections.do	// tidies injection records
do scripts/preparation/combinedrugprepout.do	
do scripts/preparation/EligibleDrugHistory.do



**************** Cohort eligibility
do scripts/preparation/final_cohort_v2.do // creates indicators for each of the inclusion criteria, and the index date

do scripts/preparation/define_lastdepression.do // finds most recent depression code on/before index
do scripts/preparation/define_lastdepressionsympt.do // finds most recent depression/symptom code on/before index



**************** Define outcomes
do scripts/preparation/causeofdeath.do	// Links underlying cause of death field to the ONS short list cause of death
do scripts/preparation/extract_selfharm_hes.do	// extracts records from hes diagnoses file related to self harm




**************** Define covariates (needs baseline date from final_cohort_v2 )
do scripts/preparation/define_baselineconditions.do // loops over all extracted conditions to indicate if present at baseline
do scripts/preparation/define_baselinemeds.do // loops over all extracted prescription info to indicate of prescibed shortly before baseline

do scripts/preparation/define_alcoholuse.do // alcohol use at baseline 
do scripts/preparation/define_ethnicity.do // ethnicity at baseline 
do scripts/preparation/define_depsev.do // max depression severity at baseline 
do scripts/preparation/define_bmi.do // bmi at baseline
do scripts/preparation/smoking_definition_master.do // smoking status at baseline 
do extract_cancer_hes.do // EXTRACTS cancer data from the HES dataset
do scripts/preparation/define_cancer.do	// cancer within 1 year before index





**************** Combine into one file for analysis
do scripts/preparation/CombineAllPreparedDatasets.do

** Keep the next file separate as need to reduce numbers after the above
do scripts/preparation/TimeVaryingAntidepExposure.do // preps time-varying antidep exposure
do scripts/preparation/selfharm30_TimeVaryingAntidepExposure.do // repeats above using enddate30 for selfharm dataset




clear
frames reset
log close masterlog
exit


