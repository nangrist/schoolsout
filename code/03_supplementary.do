clear
set more off
version 17

*===============================================================================
* Supplementary data and figures
*===============================================================================

*--------------
* Supplementary Figure 7 -- Week on Week Engagement in the Phone and SMS Treatment 
*--------------

use "data/weekly_data.dta", replace
order unique_id

recode treatment (5=1) (4=3) (1=4), gen(treat_new)
lab def treat_new_lab 0 "Control" 1 "SMS Only - Not Targeted" 2 "SMS Only - Targeted" 3 "Phone & SMS -  Not Targeted" 4 "Phone & SMS - Targeted"
lab val treat_new treat_new_lab
lab var treat_new treatment

sort unique_id week
replace phone_call_length = 0 if phone_call_length == .
drop if week ==5 // Did notimplenmt this week
tab phone_call_length
lab def phone_lab 0 "None" 1 "Less than one min" 2 "one to five min" 3 "five to ten min" 4 "More than ten min"
lab val phone_call_length phone_lab

dummieslab phone_call_length, temp(@)
gen any_engagement = 1-None

collapse phone_call_length any_engagement None Lessthanonemin onetofivemin fivetotenmin Morethantenmin, by(week treat_new)
drop if week == .

gen lessthan10min =  Lessthanonemin+onetofivemin
collapse phone_call_length any_engagement None lessthan10min Lessthanonemin onetofivemin fivetotenmin Morethantenmin, by(week)
graph twoway connected any_engagement week || connected lessthan10min week || connected Morethantenmin week, ylabel(0(.2)1) legend(order(1 "Any engagement" 2 "Less than ten min" 3 "More than ten min") pos(2) col(1) ring(0) region(fcolor(gs15)))
gr export "output/SuppFig7.pdf", replace

*--------------
* Supplement Table 1 -- Subset of Main Outcomes, Randomization-Based Inference
*--------------

use "data/master.dta", replace
local file SuppTable1

	foreach var in average_level place_value_correct parent_reported_level {
	sum `var' if treatment == 0 & `var' >=0
	local sd = r(sd)
	replace `var' = `var'/`sd'
	}
			
	dummieslab treat_pool, temp(@)
	reg average_level PhoneSMS SMS
	
	replace PhoneSMS = . if SMS == 1
	replace SMS = . if PhoneSMS == 1
	
	lab var PhoneSMS "Phone + SMS"
	lab var SMS "SMS Only"

	eststo clear
	foreach var in average_level place_value_correct parent_reported_level parent_self_efficacy  parent_perception { 
		
	eststo reg_P`var': reg `var' PhoneSMS if `var' >=0 
	ritest PhoneSMS _b[PhoneSMS], reps(100) seed(125) strata($controls): reg `var' PhoneSMS 
	matrix pvalues=r(p)
	mat colnames pvalues = PhoneSMS
	est restore reg_P`var'
	estadd matrix pvalues = pvalues
	}
	
	foreach var in average_level place_value_correct parent_reported_level parent_self_efficacy  parent_perception { 
	
		sum `var' if `var' !=.
		local obs = round(r(N))
		
		sum `var' if `var' >=0 & treat_pool == 0
		local mean = round(r(mean),.001)
		local mean: di %4.3f `mean'		
		
	eststo reg_S`var': reg `var' SMS if `var' >=0 
	ritest SMS _b[SMS], reps(100) seed(125) strata($controls): reg `var' SMS 
	matrix pvalues=r(p)
	mat colnames pvalues = SMSOnly
	est restore reg_S`var'
	estadd matrix pvalues = pvalues
		estadd local obs `obs'
		estadd local strata "Yes"
		estadd local mean `mean'
	}
		
	esttab reg_P* using "output/`file'.csv", cells(b(fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) pvalues(par({ }) fmt(3))) label noobs replace drop(_cons) mgroups("Child Learning Outcomes" "Parent Beliefs and Mechanisms", pattern(1 0 1 0 0)) 
	esttab reg_S* using "output/`file'.csv", drop(_cons) collabels(, none)  cells(b(fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) pvalues(par({ }) fmt(3))) lines se depvar nocons noobs fragment label noomit nobaselevels append starlevels( * 0.10 ** 0.05 *** 0.010)
	
*--------------
*-- Suplement Table 2 -- Subset of Main Outcomes, Joint Significance Test 
*--------------

use "data/master.dta", replace
local file1 SuppTable2a
local file2 SuppTable2b
	
	global omnibus1 average_level place_value_correct 
	global omnibus2 parent_reported_level parent_self_efficacy parent_perception

	*learning
	iebaltab $omnibus1 , grpvar(treat_pool) save("output/`file1'.xlsx") pttest onerow fnoobs ftest stdev starsnoadd replace rowvarlabel format(%9.3fc) pftest fmissok balmiss(groupmean)  notecombine 

	*parent beliefs
	iebaltab $omnibus2 , grpvar(treat_pool) save("output/`file2'.xlsx") pttest onerow fnoobs ftest stdev starsnoadd replace rowvarlabel format(%9.3fc) pftest fmissok balmiss(groupmean) notecombine
 
*--------------
* Suplement Table 3 -- Attrition
*--------------

use "data/master.dta", replace
global vars phone_call_response place_value_response average_level_response
global vars2 phone_call_response_t place_value_response_t average_level_response_t
global file SuppTable3

foreach var in $vars {
latex `var'
}

*--------------
*-- Suplement Table 4 -- Balance
*--------------

use "data/master.dta", replace
global vars enrolled_grade female age Parent perc_pas
global vars2 enrolled_grade_t female_t age_t Parent_t perc_pas_t
global file SuppTable4

foreach var in $vars {
latex `var'
}
