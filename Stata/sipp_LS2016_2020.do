
global tables ""

* Monthly Sample
use sipp_clean, clear

* Merge in OxCGRT stringency index
merge m:1 date state_code using stringency_monthly
drop if _merge==2
*replace stringency_index=0 if stringency_index==. & survey_year!=2022
*drop if stringency_index==. & survey_year==2022
drop if stringency_index==.

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
* OLS
eststo: reg ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_any = remote_any
replace remote_any = 0
predict p_ln_monthly_earnings
replace remote_any = orig_remote_any
drop orig_remote_any
gen earnings_residual = ln_monthly_earnings - p_ln_monthly_earnings

* Fixed Effects
eststo: reghdfe earnings_residual remote_any [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* OLS
eststo: reg ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_any = remote_any
replace remote_any = 0
predict p_ln_wage
replace remote_any = orig_remote_any
drop orig_remote_any
gen wage_residual = ln_wage - p_ln_wage

* Fixed Effects
eststo: reghdfe wage_residual remote_any [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* OLS
eststo: reg ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_any = remote_any
replace remote_any = 0
predict p_ln_hours
replace remote_any = orig_remote_any
drop orig_remote_any
gen hours_residual = ln_weekly_hours - p_ln_hours

* Fixed Effects
eststo: reghdfe hours_residual remote_any [aweight=person_weight], absorb(person_id date) vce(robust)

esttab using "$tables\main_LS2016_2020.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("OLS" "Resid FE" "OLS" "Resid FE" "OLS" "Resid FE") ///
 mgroups("Earnings" "Wages" "Hours", pattern(1 0 1 0 1 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
drop p_ln_monthly_earnings earnings_residual p_ln_wage wage_residual p_ln_hours hours_residual

* Remote Some
est clear
preserve
drop if remote_primary_flag==1

* Earnings
* OLS
eststo: reg ln_monthly_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_some = remote_some
replace remote_some = 0
predict p_ln_monthly_earnings
replace remote_some = orig_remote_some
drop orig_remote_some
gen earnings_residual = ln_monthly_earnings - p_ln_monthly_earnings

* Fixed Effects
eststo: reghdfe earnings_residual remote_some [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* OLS
eststo: reg ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_some = remote_some
replace remote_some = 0
predict p_ln_wage
replace remote_some = orig_remote_some
drop orig_remote_some
gen wage_residual = ln_wage - p_ln_wage

* Fixed Effects
eststo: reghdfe wage_residual remote_some [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* OLS
eststo: reg ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_some = remote_some
replace remote_some = 0
predict p_ln_hours
replace remote_some = orig_remote_some
drop orig_remote_some
gen hours_residual = ln_weekly_hours - p_ln_hours

* Fixed Effects
eststo: reghdfe hours_residual remote_some [aweight=person_weight], absorb(person_id date) vce(robust)

esttab using "$tables\main_LS2016_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})

drop p_ln_monthly_earnings earnings_residual p_ln_wage wage_residual p_ln_hours hours_residual
 
restore

* Remote Primary
est clear
preserve
drop if remote_some_flag==1

* Earnings
* OLS
eststo: reg ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_primary = remote_primary
replace remote_primary = 0
predict p_ln_monthly_earnings
replace remote_primary = orig_remote_primary
drop orig_remote_primary
gen earnings_residual = ln_monthly_earnings - p_ln_monthly_earnings

* Fixed Effects
eststo: reghdfe earnings_residual remote_primary [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* OLS
eststo: reg ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_primary = remote_primary
replace remote_primary = 0
predict p_ln_wage
replace remote_primary = orig_remote_primary
drop orig_remote_primary
gen wage_residual = ln_wage - p_ln_wage

* Fixed Effects
eststo: reghdfe wage_residual remote_primary [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* OLS
eststo: reg ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r
clonevar orig_remote_primary = remote_primary
replace remote_primary = 0
predict p_ln_hours
replace remote_primary = orig_remote_primary
drop orig_remote_primary
gen hours_residual = ln_weekly_hours - p_ln_hours

* Fixed Effects
eststo: reghdfe hours_residual remote_primary [aweight=person_weight], absorb(person_id date) vce(robust)

esttab using "$tables\main_LS2016_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021. Monthly observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Ordinary Least Squares (OLS) and Individual-Month Fixed Effects on OLS residual (Resid FE)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)
 

restore