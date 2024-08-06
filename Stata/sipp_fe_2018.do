
global tables ""

* Monthly Sample
use sipp_clean, clear

* Merge in OxCGRT stringency index
merge m:1 date state_code using stringency_monthly
drop if _merge==2
replace stringency_index=0 if stringency_index==. & survey_year!=2022
drop if stringency_index==. & survey_year==2022
*drop if stringency_index==.
keep if cal_year<2020

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

* Identifying Job Changes and Simultaneous Job Change
gen job_change_help = d.jobid_1
gen job_change = (job_change_help!=0 & job_change_help!=.)
bysort person_id cal_year: egen job_change_year = max(job_change)

gen remote_any_job_change_year = remote_any * job_change_year
gen remote_some_job_change_year = remote_some * job_change_year
gen remote_primary_job_change_year = remote_primary * job_change_year

* Getting Remote X year interactions
gen remote_any_2019 = remote_any * (cal_year==2019)
gen remote_any_2020 = remote_any * (cal_year==2020)
gen remote_any_2021 = remote_any * (cal_year==2021)
gen remote_any_2022 = remote_any * (cal_year==2022)

gen remote_some_2019 = remote_some * (cal_year==2019)
gen remote_some_2020 = remote_some * (cal_year==2020)
gen remote_some_2021 = remote_some * (cal_year==2021)
gen remote_some_2022 = remote_some * (cal_year==2022)

gen remote_primary_2019 = remote_primary * (cal_year==2019)
gen remote_primary_2020 = remote_primary * (cal_year==2020)
gen remote_primary_2021 = remote_primary * (cal_year==2021)
gen remote_primary_2022 = remote_primary * (cal_year==2022)

* Main
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

esttab using "$tables\fe_all_2018.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Main") ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours") ///
 mgroups("Any" "Hybrid" "Primarily", pattern(1 0 0 1 0 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
restore

* with Job Change and Job Change Interacted with remote status
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

 esttab using "$tables\fe_all_2018.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "w/ Job Change Interaction") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})
 
restore

* Collecting Interactions
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

esttab using "$tables\fe_job_change_2018.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any job_change_year remote_any_job_change_year) varlabels(remote_any "Remote Work" job_change_year "Job Change" remote_any_job_change_year "Remote Work X Job Change", elist(remote_any_job_change_year \bottomrule)) ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours") ///
 mgroups("Any" "Hybrid" "Primarily", pattern(1 0 0 1 0 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

restore

* with Remote by year interactions
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
 esttab using "$tables\fe_all_2018.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "w/ Year Interaction") ///
 label booktabs nodep nonum nomtitles nolines nonotes noobs collabels(none) ///
 alignment(D{.}{.}{-1})
 
restore

* Collecting Interactions
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
esttab using "$tables\fe_year_inter_2018.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any remote_any_2019) varlabels(remote_any "Remote Work" remote_any_2019 "Remote Work X 2019", elist(remote_any_2019 \bottomrule)) ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours") ///
 mgroups("Any" "Hybrid" "Primarily", pattern(1 0 0 1 0 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
restore

* with Job Changes and Remote by year interactions
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
esttab using "$tables\fe_all_2018.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "w/ Both", elist(remote_any \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2018-2019. Monthly observations of prime-age individuals with $>20$ weekly hours with at most one employer at a time, employed for full survey year. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. For hybrid regressions, primarily remote individuals are dropped and for primarily remote regressions, hybrid remote individuals are dropped to isolate effect over never-remote individuals." ///
 "Controls: Age, Age$^2$, Household Relationship, Worker Class, Occupation (2-digit), Industry (2-digit), State of Residence, Gender, Race, Education, Dingel-Niemann Teleworkability (4-digit), State COVID Infection and Death Rates") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)
 
restore

* Collecting Interactions
est clear

* Remote Any
* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Remote Some
preserve
drop if remote_primary_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

restore

* Remote Primary
preserve
drop if remote_some_flag==1

* Earnings
* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)

* Wages
* Fixed Effects
eststo: reghdfe ln_wage remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
* Hours
* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any job_change_year remote_any_job_change_year remote_any_2019 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered DN_class cov_rate death_rate [aweight=person_weight], absorb(person_id date) vce(robust)
 
esttab using "$tables\fe_job_change_year_inter_2018.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any job_change_year remote_any_job_change_year remote_any_2019) varlabels(remote_any "Remote Work" job_change_year "Job Change" remote_any_job_change_year "Remote Work X Job Change" remote_any_2019 "Remote Work X 2019", elist(remote_any_2019 \bottomrule)) ///
 label booktabs nonotes nonumbers noobs collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours" "Earnings" "Wage" "Hours") ///
 mgroups("Any" "Hybrid" "Primarily", pattern(1 0 0 1 0 0 1 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
restore