* Created 2020-05-06 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	model_outcome1.do
* Creator:	RMJ
* Date:	20200506
* Desc:	Specifies the vars to include in multiple imp and regression models
*			for all cause mortality
* Version History:
*	Date	Reference	Update
*	20200506	model_outcome1	Create file
*	20201006	model_outcome1	Update propensity score model
*************************************

**** MACROS FOR THE MODELS (all-cause mortality) 
local model i.sex ageindex age2 agesex invdose	///
	yearindex lastad1_ddd /// 
	i.(bl_intselfharm firstaddrug) /// 
	i.(antipsychotics anxiolytics gc hypnotics opioids statins analgesics) ///
	i.(severe cancer1year weightloss vte substmisuse selfharm rheumatological renal) ///
	i.(pvd pud parkinsons pancreatitis palliative neuropathicpain mobility migraine mi metastatictumour) ///
	i.(legulcer insomnia indigestion hypertension hospitaladmi hemiplegia epilepsy) ///
	i.(dyspnoea diab_comp diabetes depscale dementia copd chf cerebrovas carehome) ///
	i.(cancer asthma anxiety appetiteloss angina anaemia alcoholmisuse af)

local imputedvars bmi_i i.(townsend_i smokestat_i alcoholintake_i) ib5.ethnicity_i

exit
