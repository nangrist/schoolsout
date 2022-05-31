clear
set more off
version 17
set scheme plotplainblind
*===============================================================================
* Main Tables & Figures
*===============================================================================

*--------------
* Figure 1
*--------------

use "data/master.dta", clear

// express in SD
foreach var in operation_frac_correct place_value_correct average_level {
sum `var' if treatment == 0 & `var' >=0
local sd = r(sd)
replace `var' = `var'/`sd'
}

eststo Pooled_AvgLevel: reg average_level i.treat_pool tarl_prev if average_level >=0, r cluster(unique_id)
eststo Targeted_AvgLevel: reg average_level i.treat_target tarl_prev if average_level >=0, r cluster(unique_id)
eststo Pooled_Frac: reg operation_frac_correct i.treat_pool tarl_prev if operation_frac_correct >=0, r cluster(unique_id)
eststo Targeted_Frac: reg operation_frac_correct i.treat_target tarl_prev if operation_frac_correct >=0, r cluster(unique_id)
eststo Pooled_Place: reg place_value_correct i.treat_pool tarl_prev if operation_frac_correct >=0, r cluster(unique_id)
eststo Targeted_Place: reg place_value_correct i.treat_target tarl_prev if operation_frac_correct >=0, r cluster(unique_id)

#delimit ;
coefplot
			(Pooled_AvgLevel Targeted_AvgLevel, label("Avg Level") bcolor(orangebrown)) 
			(Pooled_Place Targeted_Place, label("Place Value") bcolor(turquoise))
			(Pooled_Frac Targeted_Frac, label("Fractions") bcolor(sea) ) 
						, 
					recast(bar) fcolor(*.5) ciopts(recast(rcap) lcolor(gray) color(%30)) citop barwidth(0.19) 
					drop(_cons tarl_prev) 
					legend(row(1) pos(6) region(fcolor(gs15)))
					levels(95) format(%9.3f) 
					vertical yline(0) legend(order(1 "Avg Level" 3 "Place Value" 5 "Fractions")) 
					xlabel(, angle(45)) mlabel("p = " + string(@pval))
				    addplot(scatter @b @at, ms(i) mlab(@b) mlabsize(vsmall) mlabpos(.5) mlabcolor(black))
					;
#delimit cr
gr export "output/Figure1.pdf", replace

*--------------
* Table 1 -- Treatment Effects on Learning Outcomes
*--------------

use "data/master.dta", clear

foreach var in average_level place_value_correct operation_frac_correct {
sum `var' if treatment == 0 & `var' >=0
local sd = r(sd)
replace `var' = `var'/`sd'
}

global vars average_level place_value_correct operation_frac_correct
global vars2 average_level_t place_value_correct_t operation_frac_correct_t
global file Table1

foreach var in $vars {
latex `var'
}

// Robustness check -- learning outcomes for households with only one participating child
egen count_kids_per_house = rowtotal(stud_level_happened_1 stud_level_happened_2 stud_level_happened_3 stud_level_happened_4 stud_level_happened_5) 

gen any_treatment = 1 if treat_pool >= 1
	replace any_treatment = 0 if treat_pool ==0

reg count_kids_per_house any_treatment, r
reg count_kids_per_house any_treatment if count_kids_per_house >0, r
reg average_level  i.treat_pool tarl_prev if average_level >= 0 & count_kids_per_house ==1 ,r

*-------------- 
* Table 2 -- Robustness Check: Random Problem
*--------------

eststo clear
use "data/master.dta", clear

local file Table2
	
	foreach var in 2 3 4 5 {
	eststo rand_`var': reg average_level_`var' i.rand  $controls if average_level_`var' >=0, r 
	test 1.rand = 2.rand = 3.rand = 4.rand
	eststo rand_`var', addscalars(ftest r(p))
	}
	eststo rand_frac: reg operation_frac_correct i.rand $controls if operation_frac_correct >=0, r 
	test 1.rand = 2.rand = 3.rand = 4.rand
	eststo rand_frac, addscalars(ftest r(p))
	
	   esttab rand_* using "output/`file'.csv", starlevels( * 0.10 ** 0.05 *** 0.010) drop(_cons tarl_prev) collabels(, none) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) stats(N ftest, fmt(0 3) labels("Observations" "F-test: equivalence across all problems")) lines label se depvar nocons noobs fragment noomit nobaselevels replace

*--------------
* Table 3 -- Parent Mechanisms: Beliefs, Self-Efficacy, and Potential Crowd Out
*--------------

use "data/master.dta", clear

foreach var in parent_reported_level {
sum `var' if treatment == 0 & `var' >=0
local sd = r(sd)
replace `var' = `var'/`sd'
}

tab parent_hours_help if treat_pool ==0

* descriptive stats 
gen Rural = 1 if residential_type == 2 | residential_type == 3
	replace Rural = 0 if residential_type == 1
tab parent_hours_help Rural if treat_pool ==0, col

dummieslab parent_hours_help, temp(hours_@)
lab var hours_None "Parent Spent No Time on Education"

global vars parent_reported_level parent_correct parent_self_efficacy parent_perception parent_work hours_None
global vars2 parent_reported_level_t parent_correct_t parent_self_efficacy_t parent_perception_t parent_work_t hours_None_t
global file Table3

foreach var in $vars {
latex `var'
}
