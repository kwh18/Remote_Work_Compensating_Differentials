
global tables ""

* Monthly Sample
use sipp_clean_annual, clear

* Drop all 1 sample obs
bysort person_id: drop if _N==1

* Find simultaneous job and amenity changes
gen job_change_help = d.jobid_1
gen job_change = (job_change_help!=0 & job_change_help!=.)

* Remote Any
gen remote_any_change_help = d.remote_any
gen to_remote_any_change = (remote_any_change_help==1)
gen away_remote_any_change = (remote_any_change_help==-1)

gen job_change_to_remote_any = job_change * to_remote_any_change
gen job_change_away_remote_any = job_change * away_remote_any_change

bysort person_id: egen changer_to_remote_any = max(job_change_to_remote_any)
bysort person_id: egen changer_away_remote_any = max(job_change_away_remote_any)
gen changer_remote_any = (changer_to_remote_any==1 | changer_away_remote_any==1)

* Remote Some
gen remote_some_change_help = d.remote_some
gen to_remote_some_change = (remote_some_change_help==1)
gen away_remote_some_change = (remote_some_change_help==-1)

gen job_change_to_remote_some = job_change * to_remote_some_change
gen job_change_away_remote_some = job_change * away_remote_some_change

bysort person_id: egen changer_to_remote_some = max(job_change_to_remote_some)
bysort person_id: egen changer_away_remote_some = max(job_change_away_remote_some)
gen changer_remote_some = (changer_to_remote_some==1 | changer_away_remote_some==1)

* Remote Primary
gen remote_primary_change_help = d.remote_primary
gen to_remote_primary_change = (remote_primary_change_help==1)
gen away_remote_primary_change = (remote_primary_change_help==-1)

gen job_change_to_remote_primary = job_change * to_remote_primary_change
gen job_change_away_remote_primary = job_change * away_remote_primary_change

bysort person_id: egen changer_to_remote_primary = max(job_change_to_remote_primary)
bysort person_id: egen changer_away_remote_primary = max(job_change_away_remote_primary)
gen changer_remote_primary = (changer_to_remote_primary==1 | changer_away_remote_primary==1)

* Merge in OxCGRT stringency index
merge m:1 year state_code using stringency_yearly
drop if _merge==2
replace stringency_index=0 if stringency_index==. & survey_year!=2022
drop if stringency_index==. & survey_year==2022
*drop if stringency_index==.

* Create categories for never/at some point remote
xtset person_id year
by person_id: egen remote_any_flag = max(remote_any)
by person_id: egen remote_some_flag = max(remote_some)
by person_id: egen remote_primary_flag = max(remote_primary)

* Cluster IV1 by State x Year
egen clust_iv = group(state_code year)

* Cluster IV2 by State x Year x Occ
egen clust_iv2 = group(state_code year occupation_code_agg)

* Find % of occupations that are remote by year by taking average of remote variables
* Potenitally interact with remote status to better satisfy exclusion restriction
sort person_id year

gen iv_interact = stringency_index * DN_class_agg

* Drop non-switchers and estimate
keep if job_change==1
// keep if changer_remote_any==1
// keep if changer_to_remote_any==1
// keep if changer_away_remote_any==1
 
est clear
* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_annual_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_annual_earnings person_id year remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_annual_earnings person_id year remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_any_earnings_switchers")

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_wage person_id year remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_wage person_id year remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_any_wage_switchers")
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_weekly_hours person_id year remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_weekly_hours person_id year remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_any_hours_switchers")

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_annual_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_annual_earnings person_id year remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_annual_earnings person_id year remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_some_earnings_switchers")

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_wage person_id year remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_wage person_id year remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_some_wage_switchers")
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_weekly_hours person_id year remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_weekly_hours person_id year remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_some_hours_switchers")

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_annual_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_annual_earnings person_id year remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_annual_earnings person_id year remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_primary_earnings_switchers")

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_wage person_id year remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_wage person_id year remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_primary_wage_switchers")
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1 [aweight=person_weight], absorb(person_id year) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_weekly_hours person_id year remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_weekly_hours person_id year remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index i.jobid_1) weight(person_weight) save_results("twfe_primary_hours_switchers")

esttab using "$tables\main_twfe_switchers.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "FE Estimator") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours") ///
 mgroups("Any" "Hybrid" "Primarily", pattern(1 0 0 1 0 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

restore