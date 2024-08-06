
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

* Roy lambda calculations
* Remote Any
probit remote_any iv_interact DN_class cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [pweight=person_weight]
predict prob_any, xb

gen lambda_plus_any = normalden(prob_any)/(1-normal(prob_any))
gen lambda_minus_any = normalden(prob_any)/normal(prob_any)

* Earnings
reg ln_monthly_earnings lambda_plus_any cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_any==1
predict y_1_earnings_any, xb

reg ln_monthly_earnings lambda_minus_any cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_any==0
predict y_2_earnings_any, xb

probit remote_any y_1_earnings_any y_2_earnings_any iv_interact DN_class

gen earnings_returns_any = y_1_earnings_any - y_2_earnings_any
sum earnings_returns_any

* Wage
reg ln_wage lambda_plus_any cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_any==1
predict y_1_wage_any, xb

reg ln_wage lambda_minus_any cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_any==0
predict y_2_wage_any, xb

probit remote_any y_1_wage_any y_2_wage_any iv_interact DN_class

gen wage_returns_any = y_1_wage_any - y_2_wage_any
sum wage_returns_any

* Hours
reg ln_weekly_hours lambda_plus_any cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_any==1
predict y_1_hours_any, xb

reg ln_weekly_hours lambda_minus_any cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_any==0
predict y_2_hours_any, xb

probit remote_any y_1_hours_any y_2_hours_any iv_interact DN_class

gen hours_returns_any = y_1_hours_any - y_2_hours_any
sum hours_returns_any

* Remote Some
probit remote_some iv_interact DN_class cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [pweight=person_weight]
predict prob_some, xb

gen lambda_plus_some = normalden(prob_some)/(1-normal(prob_some))
gen lambda_minus_some = normalden(prob_some)/normal(prob_some)

* Earnings
reg ln_monthly_earnings lambda_plus_some cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_some==1
predict y_1_earnings_some, xb

reg ln_monthly_earnings lambda_minus_some cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_some==0
predict y_2_earnings_some, xb

probit remote_some y_1_earnings_some y_2_earnings_some iv_interact DN_class

gen earnings_returns_some = y_1_earnings_some - y_2_earnings_some
sum earnings_returns_some

* Wage
reg ln_wage lambda_plus_some cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_some==1
predict y_1_wage_some, xb

reg ln_wage lambda_minus_some cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_some==0
predict y_2_wage_some, xb

probit remote_some y_1_wage_some y_2_wage_some iv_interact DN_class

gen wage_returns_some = y_1_wage_some - y_2_wage_some
sum wage_returns_some

* Hours
reg ln_weekly_hours lambda_plus_some cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_some==1
predict y_1_hours_some, xb

reg ln_weekly_hours lambda_minus_some cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_some==0
predict y_2_hours_some, xb

probit remote_some y_1_hours_some y_2_hours_some iv_interact DN_class

gen hours_returns_some = y_1_hours_some - y_2_hours_some
sum hours_returns_some

* Remote Primary
probit remote_primary iv_interact DN_class cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered [pweight=person_weight]
predict prob_primary, xb

gen lambda_plus_primary = normalden(prob_primary)/(1-normal(prob_primary))
gen lambda_minus_primary = normalden(prob_primary)/normal(prob_primary)

* Earnings
reg ln_monthly_earnings lambda_plus_primary cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_primary==1
predict y_1_earnings_primary, xb

reg ln_monthly_earnings lambda_minus_primary cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_primary==0
predict y_2_earnings_primary, xb

probit remote_primary y_1_earnings_primary y_2_earnings_primary iv_interact DN_class

gen earnings_returns_primary = y_1_earnings_primary - y_2_earnings_primary
sum earnings_returns_primary

* Wage
reg ln_wage lambda_plus_primary cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_primary==1
predict y_1_wage_primary, xb

reg ln_wage lambda_minus_primary cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_primary==0
predict y_2_wage_primary, xb

probit remote_primary y_1_wage_primary y_2_wage_primary iv_interact DN_class

gen wage_returns_primary = y_1_wage_primary - y_2_wage_primary
sum wage_returns_primary

* Hours
reg ln_weekly_hours lambda_plus_primary cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_primary==1
predict y_1_hours_primary, xb

reg ln_weekly_hours lambda_minus_primary cov_rate death_rate age age_sq i.household_relationship i.worker_class i.occupation_code_agg i.industry_code_agg i.state_code weekly_hours i.date female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered if remote_primary==0
predict y_2_hours_primary, xb

probit remote_primary y_1_hours_primary y_2_hours_primary iv_interact DN_class

gen hours_returns_primary = y_1_hours_primary - y_2_hours_primary
sum hours_returns_primary
