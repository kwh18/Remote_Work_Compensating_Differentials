
global tables ""

* Monthly Sample
use sipp_clean_keep_ue, clear

* Merge in OxCGRT stringency index
merge m:1 date state_code using stringency_monthly
drop if _merge==2
replace stringency_index=0 if stringency_index==. & survey_year!=2022
drop if stringency_index==. & survey_year==2022
*drop if stringency_index==.

* Merge in COVID rates
drop _merge
merge m:1 date state_code using covid_monthly
drop if _merge==2
replace cov_rate=0 if cov_rate==.
replace death_rate=0 if death_rate==.

* Create categories for never/at some point remote
xtset person_id date
by person_id: egen remote_any_flag = max(remote_any)
by person_id: egen remote_some_flag = max(remote_some)
by person_id: egen remote_primary_flag = max(remote_primary)

* Cluster IV1 by State x Year
egen clust_iv = group(state_code cal_year)

* Cluster IV2 by State x Year x Occ
egen clust_iv2 = group(state_code cal_year occupation_code_agg)

* Find % of occupations that are remote by year by taking average of remote variables
* Potenitally interact with remote status to better satisfy exclusion restriction
sort person_id date

gen iv_interact = stringency_index * DN_class_agg

est clear
* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_monthly_earnings person_id date remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_monthly_earnings person_id date remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_any_earnings_keep_ue")

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_wage person_id date remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_wage person_id date remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_any_wage_keep_ue")
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_weekly_hours person_id date remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_weekly_hours person_id date remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_any_hours_keep_ue")
 
* Employment
* Fixed Effects
eststo: reghdfe emp_status remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights emp_status person_id date remote_any, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt emp_status person_id date remote_any, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_any_emp_status_keep_ue")

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_monthly_earnings person_id date remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_monthly_earnings person_id date remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_some_earnings_keep_ue")

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_wage person_id date remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_wage person_id date remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_some_wage_keep_ue")
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_weekly_hours person_id date remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_weekly_hours person_id date remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_some_hours_keep_ue")
 
* Employment
* Fixed Effects
eststo: reghdfe emp_status remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights emp_status person_id date remote_some, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt emp_status person_id date remote_some, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_some_emp_status_keep_ue")

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_monthly_earnings person_id date remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_monthly_earnings person_id date remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_primary_earnings_keep_ue")

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_wage person_id date remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_wage person_id date remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_primary_wage_keep_ue")
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights ln_weekly_hours person_id date remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt ln_weekly_hours person_id date remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_primary_hours_keep_ue")
 
* Employment
* Fixed Effects
eststo: reghdfe emp_status remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1 [aweight=person_weight], absorb(person_id date) vce(robust)

*(Chaisemartin and D’Haultfoeuille 2020, 2021) technique
xi: twowayfeweights emp_status person_id date remote_primary, type(feTR) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight)
xi: did_multiplegt emp_status person_id date remote_primary, cluster(clust_iv) breps(100) seed(1234) controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class cov_rate death_rate i.jobid_1) weight(person_weight) save_results("twfe_primary_emp_status_keep_ue")

esttab using "$tables\main_keep_ue_twfe.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "FE Estimator") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("Earnings" "Wage" "Hours" "Employment" "Earnings" "Wage" "Hours" "Employment" "Earnings" "Wage" "Hours" "Employment") ///
 mgroups("Any" "Hybrid" "Primarily", pattern(1 0 0 0 1 0 0 0 1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 

restore