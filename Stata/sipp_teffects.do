
global tables ""

* Monthly Sample
use sipp_clean, clear

* Merge in OxCGRT stringency index
merge m:1 date state_code using stringency_monthly
drop if _merge==2
replace stringency_index=0 if stringency_index==. & survey_year!=2022
drop if stringency_index==. & survey_year==2022
*drop if stringency_index==.

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

 
* Remote Any
* Earnings
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

* AIPW
eststo: teffects aipw (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_monthly_earnings) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_any), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_monthly_earnings) (remote_any age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_any)

esttab using "$tables\teffects_earnings.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "AIPW" "IPW" "IPWRA" "NN" "PS" "RA") ///
 mgroups("" "teffects options", pattern(1 0 1 0 0 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

* Wage
est clear

* Counting Obs and Groups
xtreg remote_any wage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_any wage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* AIPW
eststo: teffects aipw (ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_wage) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_wage age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_any), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_wage) (remote_any age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_wage age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_any)

esttab using "$tables\teffects_wage.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "AIPW" "IPW" "IPWRA" "NN" "PS" "RA") ///
 mgroups("" "teffects options", pattern(1 0 1 0 0 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

* Hours
est clear

* Counting Obs and Groups
xtreg remote_any weekly_hours, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_any weekly_hours, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* AIPW
eststo: teffects aipw (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_weekly_hours) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_any), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_weekly_hours) (remote_any age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_any)

esttab using "$tables\teffects_hours.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "AIPW" "IPW" "IPWRA" "NN" "PS" "RA") ///
 mgroups("" "teffects options", pattern(1 0 1 0 0 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

* Remote Some
preserve
drop if remote_primary_flag==1
* Earnings
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

* AIPW
eststo: teffects aipw (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_monthly_earnings) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_some), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_monthly_earnings) (remote_some age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_some)

esttab using "$tables\teffects_earnings.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})
 
* Wage
est clear

* Counting Obs and Groups
xtreg remote_some wage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_some wage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* AIPW
eststo: teffects aipw (ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_wage) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_wage age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_some), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_wage) (remote_some age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_wage age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_some)

esttab using "$tables\teffects_wage.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})

* Hours
est clear

* Counting Obs and Groups
xtreg remote_some weekly_hours, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_some weekly_hours, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* AIPW
eststo: teffects aipw (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_weekly_hours) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_some), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_weekly_hours) (remote_some age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_some)

esttab using "$tables\teffects_hours.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})

restore


* Remote Primary
preserve
drop if remote_some_flag==1
* Earnings
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

* AIPW
eststo: teffects aipw (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_monthly_earnings) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_primary), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_monthly_earnings) (remote_primary age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_primary)

esttab using "$tables\teffects_earnings.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2018-2021. Monthly observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals.") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)
 
* Wage
est clear

* Counting Obs and Groups
xtreg remote_primary wage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_primary wage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* AIPW
eststo: teffects aipw (ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_wage) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_wage age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_primary), ematch(i.occupation_code_agg) biasadj(age age_sq weekly_hours stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_wage) (remote_primary age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_wage age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_primary)

esttab using "$tables\teffects_wage.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2018-2021. Monthly observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals.") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

* Hours
est clear

* Counting Obs and Groups
xtreg remote_primary weekly_hours, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_primary weekly_hours, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* AIPW
eststo: teffects aipw (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPW
eststo: teffects ipw (ln_weekly_hours) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* IPWRA
eststo: teffects ipwra (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index DN_class_agg) (remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* Nearest-neighbor matching
eststo: teffects nnmatch (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_primary), ematch(i.occupation_code_agg) biasadj(age age_sq stringency_index)

* Propensity-score matching
eststo: teffects psmatch (ln_weekly_hours) (remote_primary age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index)

* RA
eststo: teffects ra (ln_weekly_hours age age_sq i.household_relationship i.worker_class i.industry_code_agg i.state_code i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index) (remote_primary)

esttab using "$tables\teffects_hours.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2018-2021. Monthly observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals.") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)