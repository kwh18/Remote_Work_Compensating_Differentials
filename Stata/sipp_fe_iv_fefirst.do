
global tables ""

* Monthly Sample
use sipp_clean, clear

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

gen iv_interact = stringency_index * DN_class

* IV First Stage
gen stringency_index_100 = stringency_index / 100
est clear
reghdfe remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
predict remote_any_iv_pred

preserve
drop if remote_primary_flag==1
reghdfe remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
restore
predict remote_some_iv_pred

preserve
drop if remote_some_flag==1
reghdfe remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
restore
predict remote_primary_iv_pred

* IV2 First Stage
gen iv_interact_100 = iv_interact / 100
reghdfe remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered iv_interact cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
predict remote_any_iv2_pred

preserve
drop if remote_primary_flag==1
reghdfe remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered iv_interact cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
restore
predict remote_some_iv2_pred

preserve
drop if remote_some_flag==1
reghdfe remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered iv_interact cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
restore
predict remote_primary_iv2_pred
 
* Remote Any
gen remote_any_orig=remote_any
est clear

* Counting Obs and Groups
xtreg remote_any monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_any monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* Earnings
* IV
replace remote_any = remote_any_iv_pred
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_any = remote_any_iv2_pred
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* IV
replace remote_any = remote_any_iv_pred
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_any = remote_any_iv2_pred
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* IV
replace remote_any = remote_any_iv_pred
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_any = remote_any_iv2_pred
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

replace remote_any = remote_any_orig

esttab using "$tables\main_fefirst.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "IV" "IV2" "IV" "IV2" "IV" "IV2") ///
 mgroups("" "Wages" "Earnings" "Hours", pattern(1 0 1 0 1 0 1 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
* Remote Some
gen remote_some_orig=remote_some
preserve
drop if remote_primary_flag==1
est clear

* Counting Obs and Groups
xtreg remote_some monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_some monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* Earnings
* IV
replace remote_some = remote_some_iv_pred
eststo: reghdfe ln_monthly_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_some = remote_some_iv2_pred
eststo: reghdfe ln_monthly_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* IV
replace remote_some = remote_some_iv_pred
eststo: reghdfe ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_some = remote_some_iv2_pred
eststo: reghdfe ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* IV
replace remote_some = remote_some_iv_pred
eststo: reghdfe ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_some = remote_some_iv2_pred
eststo: reghdfe ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

replace remote_some = remote_some_orig

esttab using "$tables\main_fefirst.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})

restore


* Remote Primary
gen remote_primary_orig=remote_primary
preserve
drop if remote_some_flag==1
est clear

* Counting Obs and Groups
xtreg remote_primary monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_primary monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* Earnings
* IV
replace remote_primary = remote_primary_iv_pred
eststo: reghdfe ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_primary = remote_primary_iv2_pred
eststo: reghdfe ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* IV
replace remote_primary = remote_primary_iv_pred
eststo: reghdfe ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_primary = remote_primary_iv2_pred
eststo: reghdfe ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* IV
replace remote_primary = remote_primary_iv_pred
eststo: reghdfe ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

* IV2
replace remote_primary = remote_primary_iv2_pred
eststo: reghdfe ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate DN_class [aweight=person_weight], absorb(person_id date) vce(robust)

replace remote_primary = remote_primary_orig

esttab using "$tables\main_fefirst.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2018-2021. Monthly observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

restore