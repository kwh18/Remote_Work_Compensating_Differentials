
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

* Create UE Duration as outcome
gen unemp_status = 1-emp_status
bysort person_id cal_year: egen unemp_periods = sum(unemp_status)
 
* Remote Any
est clear

* Counting Obs and Groups
xtreg remote_any monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo N: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_any monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo n: mean `depvar'
drop `depvar'
rename holding `depvar'

* Employment Status
* OLS
eststo: reg emp_status remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe emp_status remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Unemployment Duration
* OLS
eststo: reg unemp_periods remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe unemp_periods remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls unemp_periods age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls unemp_periods age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_keep_ue_duration.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "OLS" "FE" "IV" "IV2" "OLS" "FE" "IV" "IV2") ///
 mgroups("" "Employment" "UE Duration", pattern(1 0 1 0 0 0 1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
* Remote Some
preserve
drop if remote_primary_flag==1
est clear

* Counting Obs and Groups
xtreg remote_some monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo N: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_some monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo n: mean `depvar'
drop `depvar'
rename holding `depvar'

* Employment Status
* OLS
eststo: reg emp_status remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe emp_status remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Unemployment Duration
* OLS
eststo: reg unemp_periods remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe unemp_periods remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls unemp_periods age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls unemp_periods age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_keep_ue_duration.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})

restore


* Remote Primary
preserve
drop if remote_some_flag==1
est clear

* Counting Obs and Groups
xtreg remote_primary monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo N: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_primary monthly_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo n: mean `depvar'
drop `depvar'
rename holding `depvar'

* Employment Status
* OLS
eststo: reg emp_status remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe emp_status remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Unemployment Duration
* OLS
eststo: reg unemp_periods remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe unemp_periods remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls unemp_periods age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls unemp_periods age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered cov_rate death_rate (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_keep_ue_duration.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2018-2021. Monthly observations of prime-age individuals with at most one employer at a time, employed for at least one month. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

restore