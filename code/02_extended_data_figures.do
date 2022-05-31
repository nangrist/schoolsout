clear
set more off
version 17

*===============================================================================
* Extended Data Figures
*===============================================================================

*--------------
* Ext Data 1 -- Sample Characteristics and Representativeness (created manually)
*--------------

use "data/master.dta", clear
tab region_id // regions represented
	** Overall: https://commons.wikimedia.org/wiki/File:Districts_of_Botswana_en.svg
mean female // demographics
	** Similar nationally, see WB % of population female here: https://data.worldbank.org/indicator/SP.POP.TOTL.FE.ZS?locations=BW

tab residential // (not City/Town) .. I.e., percent rural
	** National: https://data.worldbank.org/indicator/SP.RUR.TOTL.ZS?locations=BW
sum A B C // primary school leaving exam scores
	** National data from Ministry of Basic Education Primary School Leaving Exam

// Brookings data -- caregiver characteristics (beyond secondary school completion)
	** tab highest education: 12.44+4.31+11.96 = 28.71
	** National: https://data.worldbank.org/indicator/SE.TER.ENRR

*--------------
* Ext Data 2 -- Treatment on the Treated Effects
*--------------
	
use "data/master.dta", clear

merge 1:1 unique_id using  "data/tot.dta"

local file ExtData2

	replace tot = 0 if treat_pool == 0
	dummieslab treat_pool 
	replace PhoneSMS = . if SMSOnly == 1
	gen tot_c = tot*6 // scaled to all sessions 

** SD effects
foreach var in average_level {
sum `var' if treatment == 0 & `var' >=0
local sd = r(sd)
replace `var' = `var'/`sd'
}

** regs

local file ExtData2
lab var tot_c "Phone + SMS - Per Session"
lab var tot "Phone + SMS - All Sessions"

eststo end: reg average_level i.treat_pool tarl_prev
eststo iv1: ivreg2 average_level (tot_c = PhoneSMS) tarl_prev
eststo iv2: ivreg2 average_level (tot = PhoneSMS) tarl_prev

esttab end iv1 iv2 using "output/`file'.csv", drop(_cons tarl_prev 1.treat_pool) stats(N, fmt(0) labels("Observations")) collabels(, none) cells(b(fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) lines se depvar nocons noobs fragment label noomit nobaselevels replace starlevels( * 0.10 ** 0.05 *** 0.010)

*--------------
* Ext Data 3 -- Learning Gains. Non-Standardized and by Proficiency
*--------------

eststo clear
use "data/master.dta", clear

global vars3 average_level average_level_1 average_level_5 place_value_correct operation_frac_correct
global file ExtData3

foreach treat in treat_pool {
foreach dep of varlist  $vars3 {
	eststo `dep': reg `dep' i.`treat' $controls if `dep' >=0, r
	sum `dep' if `treat' == 0 & `dep' >=0
    estadd scalar mean = round(r(mean),.001)
	test 1.`treat'=2.`treat'
	eststo `dep', addscalars(equal r(p))
	estadd local strata "Yes"
	   }
	   }   

	   esttab $vars3 using "output/$file.csv", drop(_cons tarl_prev) stats(mean strata N equal, fmt(3 0 0 3) labels("Control Mean" "Strata Fixed Effects" "Observations" "p-val: SMS = Phone")) collabels(, none) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) lines se depvar nocons noobs fragment label noomit nobaselevels replace starlevels( * 0.10 ** 0.05 *** 0.010)

*--------------
* Ext Data 4 -- Learning Gains, Heterogeneous Treatment Effects
*--------------

eststo clear
use "data/master.dta", clear
dummieslab caregiver_type, temp(rel_@)
gen Rural = 1 if residential_type == 2 | residential_type == 3
	replace Rural = 0 if residential_type == 1

global vars3 average_level
global file ExtData4

foreach treat in treat_pool {
foreach dep of varlist  $vars3 {
	
	eststo `dep'_gender: reg `dep' i.`treat'##female $controls if `dep' >=0, r

		sum `dep' if `treat' == 0 & `dep' >=0
		estadd scalar mean = round(r(mean),.001)
		estadd local strata "Yes"
		
	eststo `dep'_grade: reg `dep' i.`treat'##c.enrolled_grade $controls if `dep' >=0, r

		sum `dep' if `treat' == 0 & `dep' >=0
		estadd scalar mean = round(r(mean),.001)
		estadd local strata "Yes"
		
	eststo `dep'_exam: reg `dep' i.`treat'##c.gradedscore $controls if `dep' >=0, r

		sum `dep' if `treat' == 0 & `dep' >=0
		estadd scalar mean = round(r(mean),.001)
		estadd local strata "Yes"
		
	   }
	   }   
	   
	   esttab $vars3* using "output/$file.csv", drop(_cons tarl_prev) stats(mean N, fmt(3 0 3) labels("Control Mean" "Observations")) collabels(, none) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) lines se depvar nocons noobs fragment label noomit nobaselevels replace starlevels( * 0.10 ** 0.05 *** 0.010)

*--------------
* Ext Data 5 -- Robustness Check: Effort on the Test
*--------------
	
use "data/master.dta", clear

global vars effort_question_correct average_level 
global vars2 effort_question_correct_t average_level_t 
local file ExtData5

foreach treat in treat_pool {
foreach dep in  $vars {
	eststo `dep': reg `dep' i.`treat' $controls if `dep' >=0, r
	sum `dep' if `treat' == 0 & `dep' >=0
    estadd scalar mean = round(r(mean),.001)
	test 1.`treat'=2.`treat'
	eststo `dep', addscalars(equal r(p))
	estadd local strata "Yes"
	   }
	   }   

	   esttab $vars using "output/`file'.csv", drop(_cons tarl_prev) stats(mean strata N equal, fmt(3 0 0 3) labels("Control Mean" "Strata Fixed Effects" "Observations" "p-val: SMS = Phone")) collabels(, none) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) lines se depvar nocons noobs fragment label noomit nobaselevels replace starlevels( * 0.10 ** 0.05 *** 0.010)


*--------------
* Ext Data 6 -- Known-Groups Validity Test
*--------------

use "data/master.dta", clear
 
 ** known-group tests in control group

 eststo clear
 global vars_r1 average_level
 foreach dep in  $vars_r1 {
	eststo `dep'_age: reg `dep' age if `dep' >=0 & treat_pool == 0, r
	eststo `dep'_std: reg `dep' enrolled_grade if `dep' >=0 & treat_pool == 0, r
 }

 esttab average_level* using "output/ExtData6.csv", starlevels( * 0.10 ** 0.05 *** 0.010) drop(_cons) collabels(, none) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) stats(N, fmt(0) labels("Observations")) lines label se depvar nocons noobs fragment noomit nobaselevels replace

*--------------
* Ext Data 7 -- Engagement and Demand
*--------------

 eststo clear
use "data/master.dta", clear
replace attempted_problems = 0 if treatment == 0
todummies demand_atmidline
lab var demand_atmidline1 "Phone and SMS"
lab var demand_atmidline2 "SMS Only"
lab var demand_atmidline5 "None"
local file ExtData7

foreach treat in treat_pool {
foreach dep in  attempted_problems demand_atmidline1 demand_atmidline2 demand_atmidline5 {
	eststo `dep': reg `dep' i.`treat' if `dep' >=0, r
	sum `dep' if `treat' == 0 & `dep' >=0
    estadd scalar mean = round(r(mean),.001)
	test 1.`treat'=2.`treat'
	eststo `dep', addscalars(equal r(p))
	   }
	   }   


	   esttab attempted_problems demand_atmidline1 demand_atmidline2 demand_atmidline5 using "output/`file'.csv", mgroups("Engaged" "Demand", pattern(1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))  stats(mean N equal, fmt(3 0 3) labels("Control Mean" "Observations" "p-val: SMS = Phone")) collabels(, none) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) lines se depvar nocons noobs fragment label noomit nobaselevels replace starlevels( * 0.10 ** 0.05 *** 0.010)
