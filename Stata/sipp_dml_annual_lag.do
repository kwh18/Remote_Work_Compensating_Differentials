

* Yearly Sample
use sipp_clean_annual, clear

* Merge in OxCGRT stringency index
merge m:1 year state_code using stringency_yearly_lag
drop if _merge==2
*replace stringency_index=0 if stringency_index==. & survey_year!=2022
*drop if stringency_index==. & survey_year==2022
drop if stringency_index==.

* Create categories for never/at some point remote
xtset person_id year
by person_id: egen remote_any_flag = max(remote_any)
by person_id: egen remote_some_flag = max(remote_some)
by person_id: egen remote_primary_flag = max(remote_primary)

* Cluster IV1 by State
egen clust_iv = group(state_code)

* Cluster IV2 by State x Occ
egen clust_iv2 = group(state_code occupation_code_agg)

* Find % of occupations that are remote by year by taking average of remote variables
* Potenitally interact with remote status to better satisfy exclusion restriction
sort person_id year

gen iv_interact = stringency_index * DN_class_agg

// * Remote Any
// est clear
//
// * Counting Obs and Groups
// xtreg remote_any annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// xtreg remote_any annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N_clust) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// * Earnings
// * OLS
// eststo: reg ln_annual_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_annual_earnings remote_any, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// * Wages
// * OLS
// eststo: reg ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_wage remote_any, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// esttab using "$tables\DML_ann_lag.tex", replace f ///
//  prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
//  b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
//  keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
//  label booktabs noobs nonotes nonumbers collabels(none) ///
//  alignment(D{.}{.}{-1}) ///
//  mtitles("N" "n" "OLS" "IV2" "DML" "OLS" "IV2" "DML") ///
//  mgroups("" "Earnings" "Wages", pattern(1 0 1 0 0 1 0 0) ///
//  prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
//
//
//
// * Hours
// est clear
//
// * Counting Obs and Groups
// xtreg remote_any annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// xtreg remote_any annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N_clust) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// * OLS
// eststo: reg ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_weekly_hours remote_any, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// esttab using "$tables\DML_ann_lag_hours.tex", replace f ///
//  prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
//  b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
//  keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
//  label booktabs noobs nonotes nonumbers collabels(none) ///
//  alignment(D{.}{.}{-1}) ///
//  mtitles("N" "n" "OLS" "IV2" "DML") ///
//  mgroups("" "Hours", pattern(1 0 1 0 0) ///
//  prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
// 
// * Remote Some
// preserve
// drop if remote_primary_flag==1
// est clear
//
// * Counting Obs and Groups
// xtreg remote_some annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// xtreg remote_some annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N_clust) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// * Earnings
// * OLS
// eststo: reg ln_annual_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_annual_earnings remote_some, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// * Wages
// * OLS
// eststo: reg ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_wage remote_some, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// esttab using "$tables\DML_ann_lag.tex", append f ///
//  b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
//  keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
//  label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) ///
//  alignment(D{.}{.}{-1})
//
// * Hours
// est clear
//
// * Counting Obs and Groups
// xtreg remote_some annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// xtreg remote_some annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N_clust) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// * OLS
// eststo: reg ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_weekly_hours remote_some, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// esttab using "$tables\DML_ann_lag_hours.tex", append f ///
//  b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
//  keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
//  label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) ///
//  alignment(D{.}{.}{-1})
//
// restore


* Remote Primary
preserve
drop if remote_some_flag==1
est clear

// * Counting Obs and Groups
// xtreg remote_primary annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// xtreg remote_primary annual_earnings, fe cluster(person_id)
// local depvar "`e(depvar)'"
// rename `depvar' holding
// gen `depvar'= e(N_clust) in 1
// eststo: mean `depvar'
// drop `depvar'
// rename holding `depvar'
//
// * Earnings
// * OLS
// eststo: reg ln_annual_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_annual_earnings remote_primary, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// * Wages
// * OLS
// eststo: reg ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r
//
// * IV - Interaction instrument
// eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)
//
// * Double Machine Learning
// eststo: xporegress ln_wage remote_primary, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)
//
// esttab using "$tables\DML_ann_lag.tex", append f ///
//  b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
//  keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
//  label booktabs collabels(none) nomtitles nolines nonum noobs ///
//  substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
//  addnotes("Sample: 2021. Annual observations of prime-age individuals with some weekly hours with at most one employer at a time, employed for $>7$ months of survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
//  "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2), and Double Machine Learning (DML)") ///
//  alignment(D{.}{.}{-1}) sfmt(%6.0fc)

* Hours
est clear

* Counting Obs and Groups
xtreg remote_primary annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_primary annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* OLS
eststo: reg ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Double Machine Learning
eststo: xporegress ln_weekly_hours remote_primary, controls(age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg emp_status)

esttab using "$tables\DML_ann_lag_hours.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2021. Annual observations of prime-age individuals with some weekly hours with at most one employer at a time, employed for $>7$ months of survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2), and Double Machine Learning (DML)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

restore