
global tables ""

* Monthly Sample
use sipp_clean, clear

* Merge in OxCGRT stringency index
merge m:1 date state_code using oxcgrt_indeces_monthly
drop if _merge==2
replace stringency_index=0 if stringency_index==. & survey_year!=2022
replace containment_health_index=0 if containment_health_index==. & survey_year!=2022
replace government_response_index=0 if government_response_index==. & survey_year!=2022
replace economic_support_index=0 if economic_support_index==. & survey_year!=2022
drop if (stringency_index==. | containment_health_index==. | government_response_index==. | economic_support_index==.) & survey_year==2022
*drop if stringency_index==. | containment_health_index==. | government_response_index==. | economic_support_index==.

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

gen iv_interact_stringency = stringency_index * DN_class_agg
gen iv_interact_containment_health = containment_health_index * DN_class_agg
gen iv_interact_government_response = government_response_index * DN_class_agg
gen iv_interact_economic_support = economic_support_index * DN_class_agg

* IV First Stage
gen stringency_index_100 = stringency_index / 100
gen containment_health_index_100 = containment_health_index / 100
gen government_response_index_100 = government_response_index / 100
gen economic_support_index_100 = economic_support_index / 100

est clear
eststo: reg remote_any stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], vce(cluster clust_iv)

preserve
drop if remote_primary_flag==1
eststo: reg remote_some stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], vce(cluster clust_iv)
restore

preserve
drop if remote_some_flag==1
eststo: reg remote_primary stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], vce(cluster clust_iv)
restore

esttab using "$tables\first_stage_iv_all_ind.tex", replace   ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) /// 
 keep(stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100) ///
 varlabels(stringency_index_100 "Stringency Index" containment_health_index_100 "Containment Health Index" government_response_index_100 "Government Response Index" economic_support_index_100 "Economic Support Index") ///
 mtitles("Remote Any" "Remote Some" "Remote Primary") ///
 addnotes(Period: 2018-2021) ///
 label booktabs noobs nonumbers collabels(none)

* IV2 First Stage
gen iv_interact_stringency_100 = iv_interact_stringency / 100
gen iv_int_containment_health_100 = iv_interact_containment_health / 100
gen iv_int_government_response_100 = iv_interact_government_response / 100
gen iv_interact_economic_support_100 = iv_interact_economic_support / 100

est clear
eststo: reg remote_any iv_interact_stringency_100 iv_int_containment_health_100 iv_int_government_response_100 iv_interact_economic_support_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100 [aweight=person_weight], vce(cluster clust_iv2)

preserve
drop if remote_primary_flag==1
eststo: reg remote_some iv_interact_stringency_100 iv_int_containment_health_100 iv_int_government_response_100 iv_interact_economic_support_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100 [aweight=person_weight], vce(cluster clust_iv2)
restore

preserve
drop if remote_some_flag==1
eststo: reg remote_primary iv_interact_stringency_100 iv_int_containment_health_100 iv_int_government_response_100 iv_interact_economic_support_100 age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index_100 containment_health_index_100 government_response_index_100 economic_support_index_100 [aweight=person_weight], vce(cluster clust_iv2)
restore

esttab using "$tables\first_stage_iv2_all_ind.tex", replace   ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) /// 
 keep(iv_interact_stringency_100 iv_int_containment_health_100 iv_int_government_response_100 iv_interact_economic_support_100) ///
 varlabels(iv_interact_stringency_100 "Stringency Index x Occ Remote $\%$" iv_int_containment_health_100 "Containment Health Index x Occ Remote $\%$" iv_int_government_response_100 "Government Response Index x Occ Remote $\%$" iv_interact_economic_support_100 "Economic Support Index x Occ Remote $\%$") ///
 mtitles("Remote Any" "Remote Some" "Remote Primary") ///
 addnotes(Period: 2018-2021) ///
 label booktabs noobs nonumbers collabels(none)

* Remote Any
est clear
* Earnings
* OLS
eststo: reg ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_any = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* OLS
eststo: reg ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_wage remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_any = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\all_ind_2018.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs noobs nonotes nonumbers collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("OLS" "FE" "IV" "IV2" "OLS" "FE" "IV" "IV2") ///
 mgroups("Earnings" "Wages", pattern(1 0 0 0 1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))



* Hours
est clear
* OLS
eststo: reg ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_any age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_any = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_any = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\all_ind_2018_hours.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_any) varlabels(remote_any "Remote Work (Any)") ///
 label booktabs noobs nonotes nonumbers collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("OLS" "FE" "IV" "IV2") ///
 mgroups("Hours", pattern(1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
 
* Remote Some
preserve
drop if remote_primary_flag==1
est clear
* Earnings
* OLS
eststo: reg ln_monthly_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_some = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* OLS
eststo: reg ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_wage remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_some = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\all_ind_2018.tex", append f ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) ///
 alignment(D{.}{.}{-1})

* Hours
est clear
* OLS
eststo: reg ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_some age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_some = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_some = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\all_ind_2018_hours.tex", append f ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_some) varlabels(remote_some "Remote Work (Some)") ///
 label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) ///
 alignment(D{.}{.}{-1})

restore


* Remote Primary
preserve
drop if remote_some_flag==1
est clear
* Earnings
* OLS
eststo: reg ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_primary = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

* Wages
* OLS
eststo: reg ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_wage remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_wage age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_primary = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\all_ind_2018.tex", append f ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 addnotes(Period: 2020-2021) ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

* Hours
est clear
* OLS
eststo: reg ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_weekly_hours remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_weekly_hours age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code ln_monthly_earnings i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_primary = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\all_ind_2018_hours.tex", append f ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 addnotes(Period: 2020-2021) ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)

restore


* Not dropping hybrid workers for comparison with ACS
est clear
* OLS
eststo: reg ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], r

* Fixed Effects
eststo: reghdfe ln_monthly_earnings remote_primary age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [aweight=person_weight], absorb(person_id date) vce(robust)

* IV
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered (remote_primary = stringency_index containment_health_index government_response_index economic_support_index) [aweight=person_weight], vce(cluster clust_iv)

* IV - Interaction instrument
eststo: ivregress 2sls ln_monthly_earnings age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered stringency_index containment_health_index government_response_index economic_support_index (remote_primary = iv_interact_stringency iv_interact_containment_health iv_interact_government_response iv_interact_economic_support) [aweight=person_weight], vce(cluster clust_iv2)

esttab using "$tables\ACS_all_ind_2018.tex", replace f ///
 prehead(\begin{tabular}{l*{@M}{r}} \toprule) ///
 b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "SIPP - Remote Work (Primary)") ///
 label booktabs noobs nonotes nonumbers collabels(none) ///
 alignment(D{.}{.}{-1}) ///
 mtitles("OLS" "FE" "IV" "IV2") ///
 mgroups("Earnings", pattern(1 0 0 0) ///
 prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
