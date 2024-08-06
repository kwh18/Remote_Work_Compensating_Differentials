
global tables ""

* Monthly Sample
use sipp_clean_keep_ue, clear

* Merge in OxCGRT stringency index
merge m:1 date state_code using stringency_monthly
drop if _merge==2
*replace stringency_index=0 if stringency_index==. & survey_year!=2022
*drop if stringency_index==. & survey_year==2022
drop if stringency_index==.


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
gen iv_interact_4dig = stringency_index * DN_class

* Drop Male/Female
*drop if female==1
drop if female==0

* IV First Stage
gen stringency_index_100 = stringency_index / 100
est clear
eststo: reg remote_any stringency_index_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], vce(cluster clust_iv)

preserve
drop if remote_primary_flag==1
eststo: reg remote_some stringency_index_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], vce(cluster clust_iv)
restore

preserve
drop if remote_some_flag==1
eststo: reg remote_primary stringency_index_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], vce(cluster clust_iv)
restore

esttab using "$tables\first_stage_iv_keep_ue_gen_f_2020.tex", replace   ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) /// 
 keep(stringency_index_100 age age_sq weekly_hours female hsgraduate somecollege associates bachelors highered) ///
 varlabels(stringency_index_100 "Stringency Index" age "Age" age_sq "Age$^2$" weekly_hours "Weekly Hours" female "Female" hsgraduate "HS Graduate" somecollege "Some College" associates "Associate's" bachelors "Bachelor's" highered "Graduate") ///
 mtitles("Remote Any" "Remote Some" "Remote Primary") ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021, Only Females. Monthly observations of prime-age individuals with at most one employer at a time, employed for at least one month. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals.") ///
 label booktabs noobs nonumbers collabels(none)

* IV2 First Stage
gen iv_interact_100 = iv_interact / 100
est clear
eststo: reg remote_any iv_interact_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 [aweight=person_weight], vce(cluster clust_iv2)

preserve
drop if remote_primary_flag==1
eststo: reg remote_some iv_interact_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 [aweight=person_weight], vce(cluster clust_iv2)
restore

preserve
drop if remote_some_flag==1
eststo: reg remote_primary iv_interact_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 [aweight=person_weight], vce(cluster clust_iv2)
restore

esttab using "$tables\first_stage_iv2_keep_ue_gen_f_2020.tex", replace   ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) /// 
 keep(iv_interact_100 stringency_index_100 age age_sq weekly_hours female hsgraduate somecollege associates bachelors highered) ///
 varlabels(iv_interact_100 "Stringency Index x Occ Remote $\%$" stringency_index_100 "Stringency Index" age "Age" age_sq "Age$^2$" weekly_hours "Weekly Hours" female "Female" hsgraduate "HS Graduate" somecollege "Some College" associates "Associate's" bachelors "Bachelor's" highered "Graduate") ///
 mtitles("Remote Any" "Remote Some" "Remote Primary") ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021, Only Females. Monthly observations of prime-age individuals with at most one employer at a time, employed for at least one month. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals.") ///
 label booktabs noobs nonumbers collabels(none)
 
 * IV2 First Stage - 4 digit
gen iv_interact_4dig_100 = iv_interact_4dig / 100
est clear
eststo: reg remote_any iv_interact_4dig_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 [aweight=person_weight], vce(cluster clust_iv2)

preserve
drop if remote_primary_flag==1
eststo: reg remote_some iv_interact_4dig_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 [aweight=person_weight], vce(cluster clust_iv2)
restore

preserve
drop if remote_some_flag==1
eststo: reg remote_primary iv_interact_4dig_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 [aweight=person_weight], vce(cluster clust_iv2)
restore

esttab using "$tables\first_stage_iv2_4dig_keep_ue_gen_f_2020.tex", replace   ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) /// 
 keep(iv_interact_4dig_100 stringency_index_100 age age_sq weekly_hours female hsgraduate somecollege associates bachelors highered) ///
 varlabels(iv_interact_4dig_100 "Stringency Index x Occ Remote $\%$ (4-dig)" stringency_index_100 "Stringency Index" age "Age" age_sq "Age$^2$" weekly_hours "Weekly Hours" female "Female" hsgraduate "HS Graduate" somecollege "Some College" associates "Associate's" bachelors "Bachelor's" highered "Graduate") ///
 mtitles("Remote Any" "Remote Some" "Remote Primary") ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021, Only Females. Monthly observations of prime-age individuals with at most one employer at a time, employed for at least one month. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals.") ///
 label booktabs noobs nonumbers collabels(none)

 
* Remote Any
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
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\keep_ue_gen_f_2020.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs noobs nonotes nonumbers collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "IV" "IV2" "4Dig" "IV" "IV2" "4Dig") ///
 mgroups("" "Earnings" "Wages", pattern(1 0 1 0 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))



* Hours
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

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

* Employment Status
* IV
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_any = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\keep_ue_gen_f_hours_2020.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs noobs nonotes nonumbers collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "IV" "IV2" "4Dig" "IV" "IV2" "4Dig") ///
 mgroups("" "Weekly Hours" "Employment Status", pattern(1 0 1 0 0 1 0 0) ///
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
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\keep_ue_gen_f_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) ///
 alignment(D{.}{.}{-1})

* Hours
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

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

* Employment Status
* IV
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_some = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\keep_ue_gen_f_hours_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) ///
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
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\keep_ue_gen_f_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021, Females Only. Monthly observations of prime-age individuals with at most one employer at a time, employed for at least one month. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2), and the 4-digit alternative (4Dig)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

* Hours
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

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

* Employment Status
* IV
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls emp_status age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\keep_ue_gen_f_hours_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021, Females Only. Monthly observations of prime-age individuals with at most one employer at a time, employed for at least one month. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Models: Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2), and the 4-digit alternative (4Dig)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

restore


* Not dropping hybrid workers for comparison with ACS
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

* IV
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact) [aweight=person_weight], vce(cluster clust_iv2)

* IV - Interaction instrument 4 digit
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index (remote_primary = iv_interact_4dig) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\ACS_keep_ue_gen_f_2020.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "SIPP - Remote Work (Primary)") ///
 label booktabs noobs nonotes nonumbers collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("N" "n" "IV" "IV2" "4Dig") ///
 mgroups("" "Earnings", pattern(1 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))