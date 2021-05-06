* Copyright (c) Arthritis Research UK Centre for Epidemiology, University of Manchester (2016-2018)
* 
* If you have used DrugPrep to prepare your data, please don't forget to cite the code! 
* (see CITATION.md for instructions)
* 
* this do file runs one or more pathways through the DrugPrep algorithm
* it is here that you define your data preparation options

/* NOTE - this is a modified version of the software DrugPrep v2.0.0 available from Zenodo.org.
* The original code is available here: https://doi.org/10.5281/zenodo.793774
* The original code is shared under a CC-BY-NC-ND licence (https://creativecommons.org/licenses/by-nc-nd/4.0/).
* The changes are highlighted in the individual files and here:
*	scripts/preparation/DrugPrep200/README.md
*/

*macros defining directories
*global basedir 	scripts/DrugPrep200

args DRUG	// RMJ addition

global logdir   	logs
global savedir  	data/clean/ad_
global dodir    	scripts/preparation/DrugPrep200/scripts
global datadir 		data/clean/ad`DRUG'_


*the DrugPrep scripts create a lot of temporary (drug) files, 
*so might be best to have a specific folder for these
global tempdir `creturn(tmpdir)'

do "$dodir/4_utilities/get_num_date.do"

clear
set more off

capture log close
log using $logdir/run_drugprep_$today_num, text append // append rather than replace 20200205

*define which option at each of the 10 decision nodes using local macros:

/*
Decision 1: Handle implausible qty (total number of things prescribed)
     options are  1a  use implausible value
                  1b  set to missing
                  1c1  set to mean for individual's prescriptions for that drug
                  1c2  set to mean for practice's prescriptions for that drug
                  1c3  set to mean for populations's prescriptions for that drug
                  1d1  set to median for individual's prescriptions for that drug
                  1d2  set to median for practice's prescriptions for that drug
                  1d3  set to median for population's prescriptions for that drug
                  1e1  set to mode for individual's prescriptions for that drug
                  1e2  set to mode for practice's prescriptions for that drug
                  1e3  set to mode for population's prescriptions for that drug
                  1f1  use value of individual's next prescription
                  1f2  use value of practice's next prescription
                  1f3  use value of population's next prescription
                  1g1  use value of individual's previous prescription
                  1g2  use value of practice's previous prescription  
                  1g3  use value of population's previous prescription
*/

local dec1  "1b"

/*
Decision 2:	Handle missing qty (total number of things prescribed)
     options are  2a  Leave as missing (implicitly drop this prescription)
                  2b1  set to mean for individual's prescriptions for that drug
                  2b2  set to mean for practice's prescriptions for that drug
                  2b3  set to mean for populations's prescriptions for that drug
                  2c1  set to median for individual's prescriptions for that drug
                  2c2  set to median for practice's prescriptions for that drug
                  2c3  set to median for population's prescriptions for that drug
                  2d1  set to mode for individual's prescriptions for that drug
                  2d2  set to mode for practice's prescriptions for that drug
                  2d3  set to mode for population's prescriptions for that drug
                  2e1  use value of individual's next prescription
                  2e2  use value of practice's next prescription
                  2e3  use value of population's next prescription
                  2f1  use value of individual's previous prescription
                  2f2  use value of practice's previous prescription  
                  2f3  use value of population's previous prescription
*/

local dec2  "2c1"

/*
Decision 3:	Handle implausible ndd (number of things taken per day)
     options are  3a  use implausible value
                  3b  set to missing
                  3c1  set to mean for individual's prescriptions for that drug
                  3c2  set to mean for practice's prescriptions for that drug
                  3c3  set to mean for populations's prescriptions for that drug
                  3d1  set to median for individual's prescriptions for that drug
                  3d2  set to median for practice's prescriptions for that drug
                  3d3  set to median for population's prescriptions for that drug
                  3e1  set to mode for individual's prescriptions for that drug
                  3e2  set to mode for practice's prescriptions for that drug
                  3e3  set to mode for population's prescriptions for that drug
                  3f1  use value of individual's next prescription
                  3f2  use value of practice's next prescription
                  3f3  use value of population's next prescription
                  3g1  use value of individual's previous prescription
                  3g2  use value of practice's previous prescription  
                  3g3  use value of population's previous prescription
*/

local dec3  "3b"

/*
Decision 4:	Handle missing ndd (number of things taken per day)
     options are  4a  Leave as missing (implicitly drop this prescription)
                  4b1  set to mean for individual's prescriptions for that drug
                  4b2  set to mean for practice's prescriptions for that drug
                  4b3  set to mean for populations's prescriptions for that drug
                  4c1  set to median for individual's prescriptions for that drug
                  4c2  set to median for practice's prescriptions for that drug
                  4c3  set to median for population's prescriptions for that drug
                  4d1  set to mode for individual's prescriptions for that drug
                  4d2  set to mode for practice's prescriptions for that drug
                  4d3  set to mode for population's prescriptions for that drug
                  4e1  use value of individual's next prescription
                  4e2  use value of practice's next prescription
                  4e3  use value of population's next prescription
                  4f1  use value of individual's previous prescription
                  4f2  use value of practice's previous prescription  
                  4f3  use value of population's previous prescription
*/

local dec4  "4c1"

/*
Decision 5:	Clean durations that are longer than clinically plausible
			options are:
				5a	    leave duration as it is
				5b_6	set to missing if > 6 months
				5b_12	set to missing if > 12 months
				5b_24	set to missing if > 24 months
				5c_6	set to 6 months if > 6 months
				5c_12 	set to 12 months if > 12 months
				5c_24	set to 24 months if > 24 months
*/

local dec5  "5b_6"

/*
Decision 6:	Select which stop date to use
			options are:
				6a		stop1 (start + numdays)
				6b		stop2 (start + dose_duration)
				6c		stop3 (start + qty/ndd)
				6d-e 	If only one stop available, use it
						if two available and equal, use that date
						if two available and unequal (but within x days), use mean
						if three available and unequal, use mean of closest 2 if within x days
						6d_15	x = 15
						6d_30	x = 30
						6d_60	x = 60
						6d_90	x = 90
						6e 	x = something very big, like 9,999,999. In other words use mean regardless of how unequal they are		
*/

local dec6  "6d_30"

/*
Decision 7:	Handle missing stop dates
			options are:
				7a	Leave as missing, drop prescription
				7b	Use mean for that drug for that individual
				7c	Use mean for that drug for all individuals
				7d 	Use individual mean for that drug but if not available use population mean				
*/

local dec7  "7d"

/*
Decision 8:	Handle multiple prescriptions for same product on same day
			will always drop if textid == 0 and there is another, non-zero textid
			options are:
				8a	Do nothing: implicitly sum doses as in dec9 below
				8b	use mean ndd and mean length
				8c	choose prescription with smallest ndd
				8d	choose prescription with largest ndd
				8e	choose shortest prescription
				8f	choose longest prescription
				8g	sum durations		
*/

local dec8  "8a"

/*
Decision 9:	Handle overlapping prescriptions
			options are:
				9a	do nothing, allow prescriptions to overlap (implicity sum doses)
				9b	move later prescription to next available time that this product is not prescribed
*/

local dec9  "9b"

/*
Decision 10:Handle sequential prescriptions with short gaps
			options are:
				10a		Do nothing
				10b	change stop date of first prescription to start date of next if gap is <= x
						10b_15  x = 15 days
						10b_30  x = 30 days
						10b_60  x = 60 days
*/

local dec10 "10b_15"

*run the DrugPrep algorithm:
do "$dodir/2_run_drugprep/run_decs.do" `dec1'  `dec2'  `dec3'  `dec4'   ///
                              `dec5'  `dec6'  `dec7'  `dec8'   ///
              		          `dec9'  `dec10'

log close
