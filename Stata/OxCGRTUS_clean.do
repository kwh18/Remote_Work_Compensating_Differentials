

* Stringency Index
import excel "OxCGRT_indexes_all_formatted.xlsx", sheet("Stringency Index") firstrow clear

reshape long stringency_index, i(date) j(state_code)
save stringency_daily, replace

xtset state_code date
gen l_stringency_index = l.stringency_index
drop stringency_index
rename l_stringency_index stringency_index
save stringency_daily_lag, replace

use stringency_daily, clear

gen month = mofd(date)
format month %tm
drop date
rename month date
order date
collapse stringency_index, by(date state_code)
save stringency_monthly, replace

xtset state_code date
gen l_stringency_index = l.stringency_index
drop stringency_index
rename l_stringency_index stringency_index
save stringency_monthly_lag, replace

use stringency_daily, replace
gen year = yofd(date)
format year %ty
drop date
order year

gen state="NO"
replace state="AL" if state_code==1
replace state="AK" if state_code==2
replace state="AZ" if state_code==4
replace state="AR" if state_code==5
replace state="CA" if state_code==6
replace state="CO" if state_code==8
replace state="CT" if state_code==9
replace state="DE" if state_code==10
replace state="DC" if state_code==11
replace state="FL" if state_code==12
replace state="GA" if state_code==13
replace state="HI" if state_code==15
replace state="ID" if state_code==16
replace state="IL" if state_code==17
replace state="IN" if state_code==18
replace state="IA" if state_code==19
replace state="KS" if state_code==20
replace state="KY" if state_code==21
replace state="LA" if state_code==22
replace state="ME" if state_code==23
replace state="MD" if state_code==24
replace state="MA" if state_code==25
replace state="MI" if state_code==26
replace state="MN" if state_code==27
replace state="MS" if state_code==28
replace state="MO" if state_code==29
replace state="MT" if state_code==30
replace state="NE" if state_code==31
replace state="NV" if state_code==32
replace state="NH" if state_code==33
replace state="NJ" if state_code==34
replace state="NM" if state_code==35
replace state="NY" if state_code==36
replace state="NC" if state_code==37
replace state="ND" if state_code==38
replace state="OH" if state_code==39
replace state="OK" if state_code==40
replace state="OR" if state_code==41
replace state="PA" if state_code==42
replace state="RI" if state_code==44
replace state="SC" if state_code==45
replace state="SD" if state_code==46
replace state="TN" if state_code==47
replace state="TX" if state_code==48
replace state="UT" if state_code==49
replace state="VT" if state_code==50
replace state="VA" if state_code==51
replace state="WA" if state_code==53
replace state="WV" if state_code==54
replace state="WI" if state_code==55
replace state="WY" if state_code==56

collapse stringency_index state_code, by(year state)
save stringency_yearly, replace

xtset state_code year
gen l_stringency_index = l.stringency_index
drop stringency_index
rename l_stringency_index stringency_index
save stringency_yearly_lag, replace

* Containment Health Index
import excel "OxCGRT_indexes_all_formatted.xlsx", sheet("Containment Health Index") firstrow clear

reshape long containment_health_index, i(date) j(state_code)
save containment_health_daily, replace

gen month = mofd(date)
format month %tm
drop date
rename month date
order date
collapse containment_health_index, by(date state_code)
save containment_health_monthly, replace

use containment_health_daily, replace
gen year = yofd(date)
format year %ty
drop date
order year

gen state="NO"
replace state="AL" if state_code==1
replace state="AK" if state_code==2
replace state="AZ" if state_code==4
replace state="AR" if state_code==5
replace state="CA" if state_code==6
replace state="CO" if state_code==8
replace state="CT" if state_code==9
replace state="DE" if state_code==10
replace state="DC" if state_code==11
replace state="FL" if state_code==12
replace state="GA" if state_code==13
replace state="HI" if state_code==15
replace state="ID" if state_code==16
replace state="IL" if state_code==17
replace state="IN" if state_code==18
replace state="IA" if state_code==19
replace state="KS" if state_code==20
replace state="KY" if state_code==21
replace state="LA" if state_code==22
replace state="ME" if state_code==23
replace state="MD" if state_code==24
replace state="MA" if state_code==25
replace state="MI" if state_code==26
replace state="MN" if state_code==27
replace state="MS" if state_code==28
replace state="MO" if state_code==29
replace state="MT" if state_code==30
replace state="NE" if state_code==31
replace state="NV" if state_code==32
replace state="NH" if state_code==33
replace state="NJ" if state_code==34
replace state="NM" if state_code==35
replace state="NY" if state_code==36
replace state="NC" if state_code==37
replace state="ND" if state_code==38
replace state="OH" if state_code==39
replace state="OK" if state_code==40
replace state="OR" if state_code==41
replace state="PA" if state_code==42
replace state="RI" if state_code==44
replace state="SC" if state_code==45
replace state="SD" if state_code==46
replace state="TN" if state_code==47
replace state="TX" if state_code==48
replace state="UT" if state_code==49
replace state="VT" if state_code==50
replace state="VA" if state_code==51
replace state="WA" if state_code==53
replace state="WV" if state_code==54
replace state="WI" if state_code==55
replace state="WY" if state_code==56

collapse containment_health_index state_code, by(year state)
save containment_health_yearly, replace

* Government Response Index
import excel "OxCGRT_indexes_all_formatted.xlsx", sheet("Government Response Index") firstrow clear

reshape long government_response_index, i(date) j(state_code)
save government_response_daily, replace

gen month = mofd(date)
format month %tm
drop date
rename month date
order date
collapse government_response_index, by(date state_code)
save government_response_monthly, replace

use government_response_daily, replace
gen year = yofd(date)
format year %ty
drop date
order year

gen state="NO"
replace state="AL" if state_code==1
replace state="AK" if state_code==2
replace state="AZ" if state_code==4
replace state="AR" if state_code==5
replace state="CA" if state_code==6
replace state="CO" if state_code==8
replace state="CT" if state_code==9
replace state="DE" if state_code==10
replace state="DC" if state_code==11
replace state="FL" if state_code==12
replace state="GA" if state_code==13
replace state="HI" if state_code==15
replace state="ID" if state_code==16
replace state="IL" if state_code==17
replace state="IN" if state_code==18
replace state="IA" if state_code==19
replace state="KS" if state_code==20
replace state="KY" if state_code==21
replace state="LA" if state_code==22
replace state="ME" if state_code==23
replace state="MD" if state_code==24
replace state="MA" if state_code==25
replace state="MI" if state_code==26
replace state="MN" if state_code==27
replace state="MS" if state_code==28
replace state="MO" if state_code==29
replace state="MT" if state_code==30
replace state="NE" if state_code==31
replace state="NV" if state_code==32
replace state="NH" if state_code==33
replace state="NJ" if state_code==34
replace state="NM" if state_code==35
replace state="NY" if state_code==36
replace state="NC" if state_code==37
replace state="ND" if state_code==38
replace state="OH" if state_code==39
replace state="OK" if state_code==40
replace state="OR" if state_code==41
replace state="PA" if state_code==42
replace state="RI" if state_code==44
replace state="SC" if state_code==45
replace state="SD" if state_code==46
replace state="TN" if state_code==47
replace state="TX" if state_code==48
replace state="UT" if state_code==49
replace state="VT" if state_code==50
replace state="VA" if state_code==51
replace state="WA" if state_code==53
replace state="WV" if state_code==54
replace state="WI" if state_code==55
replace state="WY" if state_code==56

collapse government_response_index state_code, by(year state)
save government_response_yearly, replace

* Economic Support Index
import excel "OxCGRT_indexes_all_formatted.xlsx", sheet("Economic Support Index") firstrow clear

reshape long economic_support_index, i(date) j(state_code)
save economic_support_daily, replace

gen month = mofd(date)
format month %tm
drop date
rename month date
order date
collapse economic_support_index, by(date state_code)
save economic_support_monthly, replace

use economic_support_daily, replace
gen year = yofd(date)
format year %ty
drop date
order year

gen state="NO"
replace state="AL" if state_code==1
replace state="AK" if state_code==2
replace state="AZ" if state_code==4
replace state="AR" if state_code==5
replace state="CA" if state_code==6
replace state="CO" if state_code==8
replace state="CT" if state_code==9
replace state="DE" if state_code==10
replace state="DC" if state_code==11
replace state="FL" if state_code==12
replace state="GA" if state_code==13
replace state="HI" if state_code==15
replace state="ID" if state_code==16
replace state="IL" if state_code==17
replace state="IN" if state_code==18
replace state="IA" if state_code==19
replace state="KS" if state_code==20
replace state="KY" if state_code==21
replace state="LA" if state_code==22
replace state="ME" if state_code==23
replace state="MD" if state_code==24
replace state="MA" if state_code==25
replace state="MI" if state_code==26
replace state="MN" if state_code==27
replace state="MS" if state_code==28
replace state="MO" if state_code==29
replace state="MT" if state_code==30
replace state="NE" if state_code==31
replace state="NV" if state_code==32
replace state="NH" if state_code==33
replace state="NJ" if state_code==34
replace state="NM" if state_code==35
replace state="NY" if state_code==36
replace state="NC" if state_code==37
replace state="ND" if state_code==38
replace state="OH" if state_code==39
replace state="OK" if state_code==40
replace state="OR" if state_code==41
replace state="PA" if state_code==42
replace state="RI" if state_code==44
replace state="SC" if state_code==45
replace state="SD" if state_code==46
replace state="TN" if state_code==47
replace state="TX" if state_code==48
replace state="UT" if state_code==49
replace state="VT" if state_code==50
replace state="VA" if state_code==51
replace state="WA" if state_code==53
replace state="WV" if state_code==54
replace state="WI" if state_code==55
replace state="WY" if state_code==56

collapse economic_support_index state_code, by(year state)
save economic_support_yearly, replace

use stringency_daily, replace
merge 1:1 date state_code using containment_health_daily, nogen
merge 1:1 date state_code using government_response_daily, nogen
merge 1:1 date state_code using economic_support_daily, nogen
save oxcgrt_indeces_daily, replace

use stringency_monthly, replace
merge 1:1 date state_code using containment_health_monthly, nogen
merge 1:1 date state_code using government_response_monthly, nogen
merge 1:1 date state_code using economic_support_monthly, nogen
save oxcgrt_indeces_monthly, replace

use stringency_yearly, replace
merge 1:1 year state using containment_health_yearly, nogen
merge 1:1 year state using government_response_yearly, nogen
merge 1:1 year state using economic_support_yearly, nogen
save oxcgrt_indeces_yearly, replace
















