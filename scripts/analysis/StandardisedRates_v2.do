* Created 2020-03-31 by Rebecca Joseph at the University of Nottingham
*************************************
* Name:	StandardisedRates_v2
* Creator:	RMJ
* Date:	20200331
* Desc:	Estimate age-sex standardised mortality/incidence rates. Uses ir, stptime,
*		and user-written command distrate
* Version History:
*	Date	Reference	Update
*	20200225	StandardisedRates	Create file
*	20200226	StandardisedRates	Finish code
*	20200331	StandardisedRates	Loop over each outcome
*	20200506	StandardisedRates	Don't include patients who start a third ad on index date
*************************************

net install distrate, from(http://fmwww.bc.edu/RePEc/bocode/d/)

set more off
frames reset
clear

use if keep1==1 & cohort<=4 using data/clean/final_combined.dta
keep if inc_thirdad==1 // for this analysis drop patients who start two antideps on index

** Required variables:  start stop outcome agecat sex cohort patid
egen agecat = cut(ageindex), at(18, 35(10)85, 100) icodes label // first group wide as few events

gen died = endreason6==1
gen start = index

gen cvdm = (died==1 & cod_L1==5)	// cardiovasc
gen cancerm = (died==1 & cod_L1==2)	// cancer
gen respm = (died==1 & cod_L1==9)	// respiratory
gen SHm = serioussh_int <= enddate6 // serious self harm

egen newstop = rowmin(enddate6 serioussh_int)
gen time = newstop - index


** Open loop
forval OUT=1/5 {

	** Copy to new frame
	frame change default
	capture frame drop live
	frame put *, into(live)

	frame change live

	** Set outcome and time variable
	if `OUT' == 1 {
		gen outcome = died
		gen stop = enddate6
		}
	if `OUT' == 2 {
		gen outcome = cvdm
		gen stop = enddate6
		}
	if `OUT' == 3 {
		gen outcome = cancerm
		gen stop = enddate6
		}
	if `OUT' == 4 {
		gen outcome = respm
		gen stop = enddate6
		}
	if `OUT' == 5 {
		gen outcome = SHm
		gen stop = newstop
		}
	 
	keep agecat start stop cohort outcome sex patid
	order cohort sex agecat

	** Keep if positive follow-up
	drop if stop < start

	**** Calculate follow-up lengths for standard population
	gen duration = (stop - start) / 365.25

	egen std_whole = sum(duration)
	bys sex: egen std_sex = sum(duration)
	bys agecat: egen std_strata1 = sum(duration)
	bys agecat sex: egen std_strata2 = sum(duration)


	*** Standardised rates with confidence intervals: user written ado distrate
	frame change live	// This means the standard population is different for the self harm outcome

	** Aggregate: number of events and follow-up by strata
	bys agecat sex cohort: egen cases=sum(outcome) 
	bys agecat sex cohort: egen pop=sum(duration)

	bys agecat sex: egen cases2 = sum(outcome)
	bys agecat sex: egen pop2 = sum(duration)

	** Two versions - standardise gender by age ignoring cohort
	capture frame drop new1
	capture frame drop new2

	frame put cohort sex agecat cases pop, into(new1)
	frame change new1
	bys agecat sex cohort: keep if _n==1

	frame change live

	frame put sex agecat cases2 pop2, into(new2)
	frame change new2
	bys agecat sex : keep if _n==1

	** Standard populations (two again)
	capture frame drop standard
	capture frame drop standard2

	frame change live
	frame put agecat sex std_strata2, into(standard)
	frame change standard
	bys agecat sex: keep if _n==1
	rename std_strata2 population
	sort agecat sex

	frame change live
	frame put agecat std_strata1, into(standard2)
	frame change standard2
	sort agecat
	by agecat: keep if _n==1
	rename std_strata1 population


	*** FIRST: standardised by age and sex
	frame change standard
	save data/clean/standard, replace

	frame change new1

	// age-sex standardise whole cohort (=crude rate as whole cohort is standard pop)
	distrate cases pop using data/clean/standard.dta, standstrata(agecat sex) popstand(population) mult(1000) saving(data/clean/standardise/std_all, replace)

	// age-sex standardise cohort, ignoring sex
	distrate cases pop using data/clean/standard.dta, standstrata(agecat sex) popstand(population) by(cohort) mult(1000)  saving(data/clean/standardise/std_cohort, replace)

	// age-sex standardise cohort over sex (so really standardising by age only)
	distrate cases pop using data/clean/standard.dta, standstrata(agecat sex) popstand(population) by(sex cohort) mult(1000)  saving(data/clean/standardise/std_sexcohort, replace)


	*** THEN: standardised by age only
	frame change standard2
	save data/clean/standard, replace

	frame change new2

	// age standardise sex
	distrate cases pop using data/clean/standard.dta, standstrata(agecat) popstand(population) by(sex) mult(1000) saving(data/clean/standardise/std_sex, replace)





	**** Create a frame to build the results table
	capture frame drop std_all

	frame create std_all
	frame change std_all

	// Load files saved in distrate
	use data/clean/standardise/std_all
	append using data/clean/standardise/std_cohort
	append using data/clean/standardise/std_sex
	append using data/clean/standardise/std_sexcohort

	** Tidy
	replace cohort = 0 if cohort==.
	replace sex = 0 if sex==.
	sort sex cohort
	order sex cohort cases N rateadj lb_gam ub_gam
	replace cases = cases2 if cases==.
	
	gen stdrate =  string(rateadj,"%9.1f") + " (" + string(lb_gam,"%9.1f") + "-" + string(ub_gam,"%9.1f") + ")" //  added 2020-03-31
	order sex cohort cases N stdrate // edit 2020-03-31
	keep sex cohort cases N stdrate // edit 2020-03-31
	label dir
	label def cohort 0 "", modify
	label def sex 0 "", modify
	rename cases nevents
	rename N personyears

	replace personyears = round(personyears)




	***** CRUDE RATES AND CIs: use command stptime; data needs to be stset including id() option
	** builds output using results in memory and scalars
	frame change live
	stset stop, origin(start) failure(outcome) scale(365.25) id(patid)

	// crude rate all
	stptime, per(1000)
	scalar def sc_crude =  string(`r(rate)',"%9.1f") + " (" + string(`r(lb)',"%9.1f") + "-" + string(`r(ub)',"%9.1f") + ")"  
	di sc_crude
	gen crude_all = sc_crude

	// crude rate all males
	stptime if sex==1, per(1000)
	scalar def sc_crude =  string(`r(rate)',"%9.1f") + " (" + string(`r(lb)',"%9.1f") + "-" + string(`r(ub)',"%9.1f") + ")"  
	di sc_crude
	gen crude_sex = sc_crude if sex==1

	// crude rate all females
	stptime if sex==2, per(1000)
	scalar def sc_crude =  string(`r(rate)',"%9.1f") + " (" + string(`r(lb)',"%9.1f") + "-" + string(`r(ub)',"%9.1f") + ")"  
	di sc_crude
	replace crude_sex = sc_crude if sex==2

	// crude rate by cohort all patients
	gen crude_cohort = ""
	forvalues X = 1/4 {
		stptime if cohort==`X', per(1000)
		scalar def sc_crude =  string(`r(rate)',"%9.1f") + " (" + string(`r(lb)',"%9.1f") + "-" + string(`r(ub)',"%9.1f") + ")"  
		di sc_crude
		replace crude_cohort = sc_crude if cohort==`X'
		}

	// crude rate by cohort and by sex
	gen crude_sexcohort = ""
	forval SEX = 1/2 {
		forval COHORT = 1/4 {
			stptime if sex==`SEX' & cohort==`COHORT', per(1000)
			scalar def sc_crude =  string(`r(rate)',"%9.1f") + " (" + string(`r(lb)',"%9.1f") + "-" + string(`r(ub)',"%9.1f") + ")"  
			di sc_crude
			replace crude_sexcohort = sc_crude if sex==`SEX' & cohort==`COHORT'
			}
		}

	** Put results into new frame and collapse down
	capture frame drop cr

	frame put sex cohort crude_*, into(cr)
	frame change cr

	sort sex cohort
	bys sex cohort: keep if _n==1


	** Link results into main results table
	frame change std_all

	frlink 1:1 sex cohort, frame(cr)
	frget *, from(cr)
	drop cr	


	sort crude_all
	replace crude_all = crude_all[_N]
	bys sex (crude_sex): replace crude_sex = crude_sex[_N]
	bys cohort (crude_cohort): replace crude_cohort = crude_cohort[_N]

	sort sex cohort

	gen cruderate = ""
	replace cruderate = crude_all if sex==0 & cohort==0
	replace cruderate = crude_sex if sex!=0 & cohort==0
	replace cruderate = crude_cohort if sex==0 & cohort!=0
	replace cruderate = crude_sexcohort if cruderate=="" // added 2020-03-31
	order cruderate, after(personyears)
	drop crude_*



	**** Use ir to generate attributable risk, as follows:
	** Use aggregated data
	frame change new1

	** Create pairwise indicator variables
	gen mvs = 1 if cohort==1
	replace mvs = 0 if cohort==2

	gen mva = 1 if cohort==1
	replace mva = 0 if cohort==3

	gen mvv = 1 if cohort==1
	replace mvv = 0 if cohort==4

	** Get standard population 
	frlink m:1 agecat sex, frame(standard)
	frget *,from(standard)
	drop standard

	** Estimate number of cases by multiplying crude rate by standard population
	gen crd = cases/pop
	gen est = crd * population
	gen standardpop2 = population/1000 // to make results per 1000py


	** use ir to get rate difference (note, results are absolute difference so 7 rather than -7); create scalar with results:
	ir est mvs standardpop2
	scalar def sc_S = string(`r(ird)',"%9.1f") + " (" + string(`r(lb_ird)',"%9.1f") + "-" + string(`r(ub_ird)',"%9.1f") + ")" 
	di sc_S

	ir est mva standardpop2
	scalar def sc_A = string(`r(ird)',"%9.1f") + " (" + string(`r(lb_ird)',"%9.1f") + "-" + string(`r(ub_ird)',"%9.1f") + ")" 
	di sc_A

	ir est mvv standardpop2
	scalar def sc_V = string(`r(ird)',"%9.1f") + " (" + string(`r(lb_ird)',"%9.1f") + "-" + string(`r(ub_ird)',"%9.1f") + ")" 
	di sc_V


	** Create var containing these scalars
	gen attrib_cohort = ""
	replace attrib_cohort = sc_S if cohort==2
	replace attrib_cohort = sc_A if cohort==3
	replace attrib_cohort = sc_V if cohort==4


	** Repeat, calculating rate difference for each cohort by sex
	// by sex
	forval X=1/2 {

		ir est mvs standardpop2 if sex==`X'
		scalar def sc_S`X' = string(`r(ird)',"%9.1f") + " (" + string(`r(lb_ird)',"%9.1f") + "-" + string(`r(ub_ird)',"%9.1f") + ")" 
		di sc_S`X'
		
		ir est mva standardpop2 if sex==`X'
		scalar def sc_A`X' = string(`r(ird)',"%9.1f") + " (" + string(`r(lb_ird)',"%9.1f") + "-" + string(`r(ub_ird)',"%9.1f") + ")" 
		di sc_A`X'
		
		ir est mvv standardpop2 if sex==`X'
		scalar def sc_V`X' = string(`r(ird)',"%9.1f") + " (" + string(`r(lb_ird)',"%9.1f") + "-" + string(`r(ub_ird)',"%9.1f") + ")" 
		di sc_V`X'

		}
		

	gen attrib_sexcohort=""
	replace attrib_s = sc_S1 if sex==1 & cohort==2
	replace attrib_s = sc_A1 if sex==1 & cohort==3
	replace attrib_s = sc_V1 if sex==1 & cohort==4

	replace attrib_s = sc_S2 if sex==2 & cohort==2
	replace attrib_s = sc_A2 if sex==2 & cohort==3
	replace attrib_s = sc_V2 if sex==2 & cohort==4	

	sort sex cohort


	** Put results into new frame and collapse
	capture frame drop srate
	frame put sex cohort attrib*, into(srate)
	frame change srate
	bys sex cohort: keep if _n==1


	** Link into main results table	
	frame change std_all	

	frlink 1:1 sex cohort, frame(srate)
	frget *, from(srate)
	drop srate

	sort cohort attrib_coh
	bys cohort (attrib_coh): replace attrib_coh = attrib_coh[_N]

	sort sex cohort
	gen attrib = ""
	replace attrib = attrib_coh if sex==0
	replace attrib = attrib_sexcoh if sex!=0
	drop attrib_coh attrib_sexcoh

	replace attrib = "reference" if cohort==1


	*** Export as table

	if `OUT'==1 {
		local name mortality
		}
	if `OUT'==2 {
		local name circulatory
		}
	if `OUT'==3 {
		local name cancer
		}
	if `OUT'==4 {
		local name respiratory
		}
	if `OUT'==5 {
		local name selfharm
		}

	export delim using "outputs/standardised_`name'.csv", replace

}


clear
frames reset
exit

