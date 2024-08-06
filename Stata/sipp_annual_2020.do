
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
*replace stringency_index=0 if stringency_index==. & survey_year!=2022
*drop if stringency_index==. & survey_year==2022
drop if stringency_index==.

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
 
* Remote Any
est clear

* Counting Obs and Groups
xtreg remote_any annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_any annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* Earnings
* OLS
eststo: reg ln_annual_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_annual_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* OLS
eststo: reg ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_annual_2020.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "OLS" "FE" "IV" "IV2" "OLS" "FE" "IV" "IV2") ///
 mgroups("" "Earnings" "Wages", pattern(1 0 1 0 0 0 1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
* Hours
est clear

* Counting Obs and Groups
xtreg remote_any annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo N: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_any annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo n: mean `depvar'
drop `depvar'
rename holding `depvar'

* OLS
eststo: reg ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_annual_hours_2020.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "OLS" "FE" "IV" "IV2") ///
 mgroups("" "Hours", pattern(1 0 1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
* Remote Some
preserve
drop if remote_primary_flag==1
est clear

* Counting Obs and Groups
xtreg remote_some annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_some annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* Earnings
* OLS
eststo: reg ln_annual_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_annual_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* OLS
eststo: reg ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_annual_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})

* Hours
est clear

* Counting Obs and Groups
xtreg remote_some annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_some annual_earnings, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* OLS
eststo: reg ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_annual_hours_2020.tex", append f ///
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

* Earnings
* OLS
eststo: reg ln_annual_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_annual_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_annual_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* OLS
eststo: reg ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_annual_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021. annual observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average annual earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

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
eststo: reg ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index [aweight=person_weight], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_annual_earnings i.year female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\main_annual_hours_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021. annual observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average annual earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

restore