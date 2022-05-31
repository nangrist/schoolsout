Name of project: 	Learning Using Low-Tech When School’s Out

Authors: 		NOAM ANGRIST, Youth Impact*, University of Oxford, World Bank; 
			PETER BERGMAN, Columbia University, NBER; 
 			& MOITSHEPI MATSHENG, Youth Impact*, Botswana National Youth Council.

			* Youth Impact was formerly known as Young 1ove.

RA support, final 
cleaning and analysis:	NATASHA AHUJA, University of Oxford 

do-files:		00_master.do calls the other (three) do files that generate all tables 
			and figures in the paper and supplementary results. Note that supplementary
			figures 1-6 are informational diagrams and Extended Data Figure 1 was manually
			put together.
			
data:			master.dta is the cleaned dataset that is used to generate all tables
			and figures. tot.dta is used to calculate the treatment on the treated effects.
			weekly_data.dta has weekly monitoring data.

instructions:		Set your folder structure in the following manner:

			projectfolder				// set this main project folder as the working directory
			|__code
			|  |__00_master.do
			|  |__01_main.do
			|  |__02_extended_data_figures.do
			|  |__03_supplementary.do
			|  			
			|__data
			|  |__master.dta
			|  |__tot.dta
			|  |__weekly_data.dta
			|
			|__output
			|
			|__README.txt