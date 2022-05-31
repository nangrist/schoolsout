clear
set more off
capture log close
set graphics off
set scheme plotplain
version 17

* need to install: 
* . ssc install estout, replace
* . ssc install coefplot, replace
* . ssc install dummieslab, replace
* . ssc install ivreg2, replace
* . ssc install ranktest, replace
* . ssc install dummies2, replace
* . ssc install ritest, replace
* . net install gr0070.pkg
* . net install ietoolkit.pkg

/*==============================================================================

Experimental Evidence on Learning Using Low-Tech When School's Out

Authors:	
- NOAM ANGRIST <noam.angrist@bsg.ox.ac.uk>
- PETER BERGMAN <psb2101@tc.columbia.edu>
- MOITSHEPI MATSHENG <mmatsheng@young1ove.org>

Research Assistance:
- NATASHA AHUJA <na697@georgetown.edu>

Date: October, 2021	

==============================================================================*/

* To create permanent directory:
*	- type ssc install fastcd (if not installed)
*	- use "cd" to set current directory to the directory where the code resides
*	  folder is located   //"NHB Replication"
*	- type in console: c cur NHB_Bots

* In this process, if Stata generates error r(603) "Stata/ado/personal/directoryfile.txt could not be opened":
*   - type sysdir to find where the PERSONAL directory is located 
*   - create an empty .txt file called "directoryfile.txt" in that PERSONAL directory
*   - type in console: c cur NHB_Bots

capture c cur NHB_Bots

** testing working directory below
use  "data/master.dta", clear

**Declaring macro for controls
global controls "tarl_prev" 

*===============================================================================
* Programs
*===============================================================================

cap prog drop latex
prog def latex
syntax varname
foreach treat in treat_pool {
foreach dep in $vars {
	eststo `dep': reg `dep' i.`treat' $controls  if `dep' >=0, r
	sum `dep' if `treat' == 0 & `dep' >=0
    estadd scalar mean = round(r(mean),.001)
	test 1.`treat'=2.`treat'
	local equal_`dep' = `r(p)'
	   }
	   }   
foreach treat in treat_target {
foreach dep in $vars  {
	eststo `dep'_t: reg `dep' i.`treat' $controls if `dep' >=0, r
	sum `dep' if `treat' == 0 & `dep' >=0
    estadd scalar mean = round(r(mean),.001)
	test 1.`treat'=2.`treat'
	eststo `dep'_t, addscalars(equalt r(p))
	estadd scalar equal = `equal_`dep''
	estadd local strata "Yes"
	   }
	   }
	
	   esttab $vars using "output/$file.csv", collabels(, none) drop(_cons tarl_prev) cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) lines se depvar nocons noobs posthead("") fragment label noomit nobaselevels replace starlevels( * 0.10 ** 0.05 *** 0.010)
	   esttab $vars2 using "output/$file.csv", collabels(, none) drop(_cons tarl_prev)  cells(b( fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3)) ci(fmt(3) par({ " to " }))) stats(mean N equal equalt, fmt(3 0 3 3) labels("Control Mean" "Observations" "p-val: SMS = Phone" "p-val: Targeted = Not Targeted")) nonumbers nomtitles lines se depvar nocons posthead("") fragment label noomit nobaselevels append starlevels( * 0.10 ** 0.05 *** 0.010) 
	   
	end

// ci(fmt(3) par)
*===============================================================================
* Main text
*===============================================================================

*** Figure 1 & Tables 1-3 in the main text
run "code/01_main.do"

*===============================================================================
* Extended data figures
*===============================================================================

*** Extended Data Figure 1-7
run "code/02_extended_data_figures.do"

*===============================================================================
* Supplementary tables and figures
*===============================================================================

*** Supplementary Table 1-4 and Supplementary Figure 7
* Note that Supplementary Figures 1-6 are informational diagrams.
run "code/03_supplementary.do"
