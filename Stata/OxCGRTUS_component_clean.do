

import excel "OxCGRT_components_simple.xlsx", sheet("components") firstrow clear

gen state_code=0
replace state_code=1 if state=="AL"
replace state_code=2 if state=="AK" 
replace state_code=4 if state=="AZ"
replace state_code=5 if state=="AR"
replace state_code=6 if state=="CA"
replace state_code=8 if state=="CO"
replace state_code=9 if state=="CT"
replace state_code=10 if state=="DE"
replace state_code=11 if state=="DC"
replace state_code=12 if state=="FL"
replace state_code=13 if state=="GA"
replace state_code=15 if state=="HI"
replace state_code=16 if state=="ID"
replace state_code=17 if state=="IL"
replace state_code=18 if state=="IN"
replace state_code=19 if state=="IA"
replace state_code=20 if state=="KS"
replace state_code=21 if state=="KY"
replace state_code=22 if state=="LA"
replace state_code=23 if state=="ME"
replace state_code=24 if state=="MD"
replace state_code=25 if state=="MA"
replace state_code=26 if state=="MI"
replace state_code=27 if state=="MN"
replace state_code=28 if state=="MS"
replace state_code=29 if state=="MO"
replace state_code=30 if state=="MT"
replace state_code=31 if state=="NE"
replace state_code=32 if state=="NV"
replace state_code=33 if state=="NH"
replace state_code=34 if state=="NJ"
replace state_code=35 if state=="NM"
replace state_code=36 if state=="NY"
replace state_code=37 if state=="NC"
replace state_code=38 if state=="ND"
replace state_code=39 if state=="OH"
replace state_code=40 if state=="OK"
replace state_code=41 if state=="OR"
replace state_code=42 if state=="PA"
replace state_code=44 if state=="RI"
replace state_code=45 if state=="SC"
replace state_code=46 if state=="SD"
replace state_code=47 if state=="TN"
replace state_code=48 if state=="TX"
replace state_code=49 if state=="UT"
replace state_code=50 if state=="VT"
replace state_code=51 if state=="VA"
replace state_code=53 if state=="WA"
replace state_code=54 if state=="WV"
replace state_code=55 if state=="WI"
replace state_code=56 if state=="WY"

save components_daily, replace

gen month = mofd(date)
format month %tm
drop date
rename month date
order date
collapse school	workplace public_events gathering public_transport stay_at_home internal_movement international_travel income_support debt_relief public_info testing_policy contact_tracing facial_coverings vaccine_policy elderly_protection vaccine_prioritization vaccine_eligibility vaccine_financial vaccine_mandate portion_vaccinated, by(date state_code)
save components_monthly, replace

use components_daily, replace
gen year = yofd(date)
format year %ty
drop date
order year
collapse school	workplace public_events gathering public_transport stay_at_home internal_movement international_travel income_support debt_relief public_info testing_policy contact_tracing facial_coverings vaccine_policy elderly_protection vaccine_prioritization vaccine_eligibility vaccine_financial vaccine_mandate portion_vaccinated, by(year state)
save components_yearly, replace