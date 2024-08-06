import delimited "SIPP_full_sample.csv", clear

save sipp_dirty, replace
use sipp_dirty, clear

* drop duplicates
order ssuid pnum survey_year spanel monthcode swave
sort ssuid pnum survey_year monthcode swave
by ssuid pnum survey_year monthcode: gen dup = cond(_N==1,0,_n)
tab dup
drop if dup>0
drop dup

* Set panel and time vars
gen cal_year = survey_year-1
gen modate = ym(cal_year, monthcode)
format modate %tm

egen person_id = group(ssuid pnum)
order person_id modate spanel
sort person_id modate

xtset person_id modate

* Keep only prime age workers (for whole panel)
tab tage
sort person_id modate
by person_id: gen minage = tage[1]
by person_id: gen maxage = tage[_N]
drop if minage<25 | maxage>55

* Sometimes age is miscoded, drop obs in which this is the case
by person_id: gen age_quirk_flag = (tage<minage | tage>maxage)
drop if age_quirk_flag==1
order person_id modate tage minage maxage
tab tage

* Drop self-employed and other work arrangement (at any point)
tab ejb1_jborse
sort person_id ejb1_jborse
by person_id: egen max_jborse = max(ejb1_jborse)
drop if max_jborse==2 | max_jborse==3
tab ejb1_jborse

* Renaming some vars
rename tehc_st state_code
rename ejb1_pvtrprm transport
rename ejb1_wshmwrk remote_any
rename ejb1_pvwktr9 remote_edited
rename enjflag emp_status

* Drop those with unemployment spells
sort person_id emp_status
replace emp_status = emp_status - 1
tab emp_status
by person_id: egen min_emp_status = min(emp_status)
drop if missing(min_emp_status)
drop if min_emp_status==0

* Make sure they have work hours
sum tjb1_wkhrs1 tjb1_wkhrs2 tjb1_wkhrs3 tjb1_wkhrs4 tjb1_wkhrs5, d
drop if tjb1_wkhrs1==. | tjb1_wkhrs2==. | tjb1_wkhrs3==. | tjb1_wkhrs4==. | tjb1_wkhrs1==0 | tjb1_wkhrs2==0 | tjb1_wkhrs3==0 | tjb1_wkhrs4==0 | tjb1_jobhrs1==0

sum tjb1_wkhrs1 tjb1_wkhrs2 tjb1_wkhrs3 tjb1_wkhrs4 tjb1_wkhrs5, d

* Aggregate weekly hours to monthly
gen annual_hours = tjb1_wkhrs1 + tjb1_wkhrs2 + tjb1_wkhrs3 + tjb1_wkhrs4
replace annual_hours = annual_hours + tjb1_wkhrs5 if tjb1_wkhrs5!=.
sum annual_hours, d

* Fixing issue with 2018 coding
replace remote_any = 2-remote_any
replace remote_edited = 2-remote_edited
replace remote_any = 1 if remote_edited==1

* Set remote status equal to last nonmissing remote status
by person_id (modate), sort: replace remote_any = remote_any[_n-1] if remote_any >= .

gen remote_primary = (transport==9)
replace remote_primary = . if transport==.
by person_id (modate), sort: replace remote_primary = remote_primary[_n-1] if remote_primary >= .
drop transport

gen remote_some = .
replace remote_some = 0 if remote_any!=.
replace remote_some = 1 if remote_primary==0 & remote_any==1

* Collapsing vars we care about
sum
bysort person_id survey_year: egen state_code_mode=mode(state_code)
bysort person_id survey_year: egen tjb1_occ_mode=mode(tjb1_occ)
bysort person_id survey_year: egen tjb1_ind_mode=mode(tjb1_ind)
bysort person_id survey_year: egen remote_any_mode=mode(remote_any)
bysort person_id survey_year: egen remote_some_mode=mode(remote_some)
bysort person_id survey_year: egen remote_primary_mode=mode(remote_primary)
bysort person_id survey_year: egen erelrpe_mode=mode(erelrpe)
bysort person_id survey_year: egen esex_mode=mode(esex)
bysort person_id survey_year: egen eorigin_mode=mode(eorigin)
bysort person_id survey_year: egen erace_mode=mode(erace)
bysort person_id survey_year: egen eeduc_mode=mode(eeduc)
bysort person_id survey_year: egen ejb1_clwrk_mode=mode(ejb1_clwrk)
bysort person_id survey_year: egen ejb1_jobid_mode=mode(ejb1_jobid)
collapse (firstnm) state_code_mode tjb1_occ_mode tjb1_ind_mode tage remote_any_mode remote_some_mode remote_primary_mode ssuid pnum survey_year erelrpe_mode esex_mode eorigin_mode erace_mode eeduc_mode ejb1_clwrk_mode ejb1_jobid_mode (mean) spanel wpfinwgt ejb1_dyswkd ejb1_dyswkdh ejb1_empsize tjb1_jobhrs1 tjb2_jobhrs1 rtanf_mnyn emp_status (sum) monthcode tptotinc tpearn_alt annual_hours, by(person_id cal_year)
rename state_code_mode state_code
rename tjb1_occ_mode tjb1_occ
rename tjb1_ind_mode tjb1_ind
rename remote_any_mode remote_any
rename remote_some_mode remote_some
rename remote_primary_mode remote_primary
rename erelrpe_mode erelrpe
rename esex_mode esex
rename eorigin_mode eorigin
rename erace_mode erace
rename eeduc_mode eeduc
rename ejb1_clwrk_mode ejb1_clwrk
rename ejb1_jobid_mode ejb1_jobid
sum

xtset person_id cal_year

* Drop those that ever lived outside of US
tab state_code
by person_id: egen max_state = max(state_code)
drop if max_state>59
tab state_code

* Dropping those with multiple jobs
tab tjb2_jobhrs1
by person_id: gen miss1 = !missing(tjb2_jobhrs1)
by person_id: egen missing_tjb2_jobhrs1 = max(miss1)
drop if missing_tjb2_jobhrs1 == 1
tab tjb2_jobhrs1

// * Dropping cases with blank ERELRPE
// tab erelrpe
// drop if erelrpe==.

* Dropping outliers in average earnings
bysort person_id: egen avg_earnings = mean(tpearn_alt)
sum avg_earnings, d
keep if inrange(avg_earnings, r(p1), r(p99)) | avg_earnings==.

* Recoding Indicator Variables
gen female = esex-1
drop esex

gen hispanic = (eorigin==1)
drop eorigin

gen black = (erace==2)
gen asian = (erace==3)
gen resid_race = (erace==4)
drop erace

gen hsdropout = (eeduc<39)
gen hsgraduate = (eeduc==39)
gen somecollege = (eeduc>39 & eeduc<42)
gen associates = (eeduc==42)
gen bachelors = (eeduc==43)
gen highered = (eeduc>43)

* Renaming Variables
rename ssuid household_ID
rename spanel panel_year
rename pnum person_number
rename erelrpe household_relationship
rename wpfinwgt person_weight
rename ejb1_clwrk worker_class
rename ejb1_dyswkd days_worked
rename ejb1_dyswkdh days_remote
rename tjb1_occ occupation_code
rename tjb1_ind industry_code
rename tjb1_jobhrs1 weekly_hours
rename tage age
rename tptotinc annual_earnings_total
rename tpearn_alt annual_earnings
rename ejb1_empsize employer_size
rename ejb1_jobid jobid_1

* Rough hourly wage calculation
gen wage = annual_earnings/annual_hours
sum wage, d

* log on Income
gen ln_annual_earnings = ln(annual_earnings)
gen ln_wage = ln(wage)
gen ln_weekly_hours = ln(weekly_hours)

* Generate variables as future earnings growth
gen ln_annual_earnings_yoy_forward = F.ln_annual_earnings - ln_annual_earnings
gen ln_wage_yoy_forward = F.ln_wage - ln_wage

* Fraction of days worked remote
gen remote_fraction = days_remote/days_worked
gen remote_fraction_0 = (remote_fraction==0)
gen remote_fraction_lt_50 = (remote_fraction>0 & remote_fraction<.5)
gen remote_fraction_gt_50 = (remote_fraction>=.5 & remote_fraction<1)
gen remote_fraction_1 = (remote_fraction==1)

* Create Experience proxy using age x education level
gen exp_hsgraduate = age * hsgraduate
gen exp_somecollege = age * somecollege
gen exp_associates = age * associates
gen exp_bachelors = age * bachelors
gen exp_highered = age * highered

* Recoding Industry codes
gen industry = ""
replace industry = "Agriculture, Forestry, Fishing, and Hunting" if inrange(industry_code,170,290)
replace industry = "Mining, Quarrying, and Oil and Gas Extraction" if inrange(industry_code,370,490)
replace industry = "Construction" if industry_code==770
replace industry = "Manufacturing" if inrange(industry_code,1070,3990)
replace industry = "Wholesale Trade" if inrange(industry_code,4070,4590)
replace industry = "Retail Trade" if inrange(industry_code,4670,5790)
replace industry = "Transportation and Warehousing" if inrange(industry_code,6070,6390)
replace industry = "Utilities" if inrange(industry_code,570,690)
replace industry = "Information" if inrange(industry_code,6470,6780)
replace industry = "Finance and Insurance" if inrange(industry_code,6870,6992)
replace industry = "Real Estate and Rental and Leasing" if inrange(industry_code,7071,7190)
replace industry = "Professional, Scientific, and Technical Services" if inrange(industry_code,7270,7490)
replace industry = "Management of companies and enterprises" if industry_code==7570
replace industry = "Administrative and support and waste management services" if inrange(industry_code,7580,7790)
replace industry = "Educational Services" if inrange(industry_code,7860,7890)
replace industry = "Health Care and Social Assistance" if inrange(industry_code,7970,8470)
replace industry = "Arts, Entertainment, and Recreation" if inrange(industry_code,8561,8590)
replace industry = "Accommodation and Food Services" if inrange(industry_code,8660,8690)
replace industry = "Other Services, Except Public Administration" if inrange(industry_code,8770,9290)
replace industry = "Public Administration" if inrange(industry_code,9370,9590)
replace industry = "Military" if inrange(industry_code,9670,9890)

gen industry_code_agg = .
replace industry_code_agg = 1 if inrange(industry_code,170,290)
replace industry_code_agg = 2 if inrange(industry_code,370,490)
replace industry_code_agg = 3 if industry_code==770
replace industry_code_agg = 4 if inrange(industry_code,1070,3990)
replace industry_code_agg = 5 if inrange(industry_code,4070,4590)
replace industry_code_agg = 6 if inrange(industry_code,4670,5790)
replace industry_code_agg = 7 if inrange(industry_code,6070,6390)
replace industry_code_agg = 8 if inrange(industry_code,570,690)
replace industry_code_agg = 9 if inrange(industry_code,6470,6780)
replace industry_code_agg = 10 if inrange(industry_code,6870,6992)
replace industry_code_agg = 11 if inrange(industry_code,7071,7190)
replace industry_code_agg = 12 if inrange(industry_code,7270,7490)
replace industry_code_agg = 13 if industry_code==7570
replace industry_code_agg = 14 if inrange(industry_code,7580,7790)
replace industry_code_agg = 15 if inrange(industry_code,7860,7890)
replace industry_code_agg = 16 if inrange(industry_code,7970,8470)
replace industry_code_agg = 17 if inrange(industry_code,8561,8590)
replace industry_code_agg = 18 if inrange(industry_code,8660,8690)
replace industry_code_agg = 19 if inrange(industry_code,8770,9290)
replace industry_code_agg = 20 if inrange(industry_code,9370,9590)
replace industry_code_agg = 21 if inrange(industry_code,9670,9890)
drop if industry_code_agg == 21

* Recoding Occupation codes
gen occupation = ""
gen DN_class_agg = 0
replace occupation = "Management" if inrange(occupation_code,10,440)
replace DN_class_agg = 0.87 if inrange(occupation_code,10,440)
replace occupation = "Business and Financial Operations" if inrange(occupation_code,500,960)
replace DN_class_agg = 0.88 if inrange(occupation_code,500,960)
replace occupation = "Computer and Mathematical" if inrange(occupation_code,1005,1240)
replace DN_class_agg = 1 if inrange(occupation_code,1005,1240)
replace occupation = "Architecture and Engineering" if inrange(occupation_code,1305,1560)
replace DN_class_agg = 0.61 if inrange(occupation_code,1305,1560)
replace occupation = "Life, Physical, and Social Science" if inrange(occupation_code,1600,1980)
replace DN_class_agg = 0.54 if inrange(occupation_code,1600,1980)
replace occupation = "Community and Social Service" if inrange(occupation_code,2001,2060)
replace DN_class_agg = 0.37 if inrange(occupation_code,2001,2060)
replace occupation = "Legal" if inrange(occupation_code,2100,2180)
replace DN_class_agg = 0.97 if inrange(occupation_code,2100,2180)
replace occupation = "Educational Instruction, and Library" if inrange(occupation_code,2205,2555)
replace DN_class_agg = 0.98 if inrange(occupation_code,2205,2555)
replace occupation = "Arts, Design, Entertainment, Sports, and Media" if inrange(occupation_code,2600,2970)
replace DN_class_agg = 0.76 if inrange(occupation_code,2600,2970)
replace occupation = "Healthcare Practitioners and Technical" if inrange(occupation_code,3000,3550)
replace DN_class_agg = 0.05 if inrange(occupation_code,3000,3550)
replace occupation = "Healthcare Support" if inrange(occupation_code,3601,3655)
replace DN_class_agg = 0.02 if inrange(occupation_code,3601,3655)
replace occupation = "Protective Service" if inrange(occupation_code,3700,3960)
replace DN_class_agg = 0.06 if inrange(occupation_code,3700,3960)
replace occupation = "Food Preparation and Serving Related" if inrange(occupation_code,4000,4160)
replace occupation = "Building and Grounds Cleaning and Maintenance" if inrange(occupation_code,4200,4255)
replace occupation = "Personal Care and Service" if inrange(occupation_code,4330,4655)
replace DN_class_agg = 0.26 if inrange(occupation_code,4330,4655)
replace occupation = "Sales and Related" if inrange(occupation_code,4700,4965)
replace DN_class_agg = 0.28 if inrange(occupation_code,4700,4965)
replace occupation = "Office and Administrative Support" if inrange(occupation_code,5000,5940)
replace DN_class_agg = 0.65 if inrange(occupation_code,5000,5940)
replace occupation = "Farming, Fishing, and Forestry" if inrange(occupation_code,6005,6130)
replace DN_class_agg = 0.01 if inrange(occupation_code,6005,6130)
replace occupation = "Construction and Extraction" if inrange(occupation_code,6200,6950)
replace occupation = "Installation, Maintenance, and Repair" if inrange(occupation_code,7000,7640)
replace DN_class_agg = 0.01 if inrange(occupation_code,7000,7640)
replace occupation = "Production" if inrange(occupation_code,7700,8990)
replace DN_class_agg = 0.01 if inrange(occupation_code,7700,8990)
replace occupation = "Transportation" if inrange(occupation_code,9005,9430)
replace DN_class_agg = 0.03 if inrange(occupation_code,9005,9430)
replace occupation = "Material Moving" if inrange(occupation_code,9510,9760)
replace DN_class_agg = 0.03 if inrange(occupation_code,9510,9760)
replace occupation = "Military Specific" if inrange(occupation_code,9800,9840)

gen occupation_code_agg = .
replace occupation_code_agg = 1 if inrange(occupation_code,10,440)
replace occupation_code_agg = 2 if inrange(occupation_code,500,960)
replace occupation_code_agg = 3 if inrange(occupation_code,1005,1240)
replace occupation_code_agg = 4 if inrange(occupation_code,1305,1560)
replace occupation_code_agg = 5 if inrange(occupation_code,1600,1980)
replace occupation_code_agg = 6 if inrange(occupation_code,2001,2060)
replace occupation_code_agg = 7 if inrange(occupation_code,2100,2180)
replace occupation_code_agg = 8 if inrange(occupation_code,2205,2555)
replace occupation_code_agg = 9 if inrange(occupation_code,2600,2970)
replace occupation_code_agg = 10 if inrange(occupation_code,3000,3550)
replace occupation_code_agg = 11 if inrange(occupation_code,3601,3655)
replace occupation_code_agg = 12 if inrange(occupation_code,3700,3960)
replace occupation_code_agg = 13 if inrange(occupation_code,4000,4160)
replace occupation_code_agg = 14 if inrange(occupation_code,4200,4255)
replace occupation_code_agg = 15 if inrange(occupation_code,4330,4655)
replace occupation_code_agg = 16 if inrange(occupation_code,4700,4965)
replace occupation_code_agg = 17 if inrange(occupation_code,5000,5940)
replace occupation_code_agg = 18 if inrange(occupation_code,6005,6130)
replace occupation_code_agg = 19 if inrange(occupation_code,6200,6950)
replace occupation_code_agg = 20 if inrange(occupation_code,7000,7640)
replace occupation_code_agg = 21 if inrange(occupation_code,7700,8990)
replace occupation_code_agg = 22 if inrange(occupation_code,9005,9430)
replace occupation_code_agg = 23 if inrange(occupation_code,9510,9760)
replace occupation_code_agg = 24 if inrange(occupation_code,9800,9840)
drop if occupation_code_agg == 24

* Checking weights
sum person_weight, d

* Generate various needed vars
gen age_sq = age^2

* Generate variables indicating individuals that will be remote in future, but not in present.
sort person_id cal_year
gen remote_any_cal_year = remote_any * cal_year
replace remote_any_cal_year =. if remote_any_cal_year==0
by person_id: egen remote_any_cal_year_min = min(remote_any_cal_year)
gen remote_any_later = (cal_year<remote_any_cal_year_min) & !missing(remote_any_cal_year_min)
gen remote_any_plus_later = remote_any_later + remote_any
drop remote_any_cal_year remote_any_cal_year_min

gen remote_some_cal_year = remote_some * cal_year
replace remote_some_cal_year =. if remote_some_cal_year==0
by person_id: egen remote_some_cal_year_min = min(remote_some_cal_year)
gen remote_some_later = (cal_year<remote_some_cal_year_min) & !missing(remote_some_cal_year_min)
gen remote_some_plus_later = remote_some_later + remote_some
drop remote_some_cal_year remote_some_cal_year_min

gen remote_primary_cal_year = remote_primary * cal_year
replace remote_primary_cal_year =. if remote_primary_cal_year==0
by person_id: egen remote_primary_cal_year_min = min(remote_primary_cal_year)
gen remote_primary_later = (cal_year<remote_primary_cal_year_min) & !missing(remote_primary_cal_year_min)
gen remote_primary_plus_later = remote_primary_later + remote_primary
drop remote_primary_cal_year remote_primary_cal_year_min

* Reordering Variables
order person_id cal_year state_code person_weight annual_earnings wage remote_any remote_some remote_primary days_remote days_worked age
sort person_id cal_year
rename cal_year year
sum

save sipp_clean_annual, replace