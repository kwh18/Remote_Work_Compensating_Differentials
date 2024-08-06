
use sipp_clean, clear
global tables ""

label var monthly_earnings "Monthly Earnings"
label var wage "Wage"
label var remote_any "Any WFH"
label var remote_primary "Primarily WFH"
label var remote_some "Hybrid WFH"
label var days_remote "WFH Days per Week"
label var days_worked "Work Days per Week"
label var remote_fraction "Percent Days WFH"
label var weekly_hours "Weekly Hours"
label var age "Age"
label var female "Female"
label var hispanic "Hispanic"
label var black "Black"
label var asian "Asian"
label var hsdropout "High School Dropout"
label var hsgraduate "High School Graduate"
label var somecollege "Some College"
label var associates "Associate's Degree"
label var bachelors "Bachelor's Degree"
label var highered "Graduate Degree"


sum
sum [aweight=person_weight]

est clear
estpost tabstat monthly_earnings wage remote_any remote_primary remote_some days_remote days_worked remote_fraction weekly_hours age female hispanic black asian hsdropout hsgraduate somecollege associates bachelors highered [aweight=person_weight], c(stat) stat(n mean sd min max)
esttab using "$tables\sum_stats.tex", replace   ///
 cells("count(fmt(%9.3gc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max") nonumber /// 
 nomtitle nonote noobs label booktabs ///
 collabels("N" "Mean" "SD" "Min" "Max") ///
 prehead(`"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"' ///
         `"\begin{tabular}{l*{1}{ccccc}}"') ///
 postfoot(`"\end{tabular}"') ///
 title("Summary Stats")

* Breakdown Summary Stats by Remote Status
sum if remote_any==0 [aweight=person_weight]
sum if remote_any==1 & remote_primary==0 [aweight=person_weight]
sum if remote_primary==1 [aweight=person_weight]

gen remote_status = 0
replace remote_status = 1 if remote_some==1
replace remote_status = 2 if remote_primary==1

est clear
estpost tabstat monthly_earnings wage days_remote days_worked remote_fraction weekly_hours age female hispanic black asian hsdropout hsgraduate somecollege associates bachelors highered [aweight=person_weight], by(remote_status) c(stat) stat(mean) nototal
esttab using "$tables\sum_stats_by_remote.tex", replace   ///
 main(mean %9.2fc) nostar nonumber unstack /// 
 compress nonote noobs gap label booktabs ///
 collabels(none) ///
 eqlabels("In Person" "Hybrid" "Primarily WFH") /// 
 prehead(`"\begin{tabular}{l*{3}{c}}"') ///
 postfoot(`"\end{tabular}"') ///
 nomtitles ///
 title("Summary Stats by Remote Status")

sum monthly_earnings if remote_any==0 [aweight=person_weight], d
sum monthly_earnings if remote_any==1 & remote_primary==0 [aweight=person_weight], d
sum monthly_earnings if remote_primary==1 [aweight=person_weight], d
sum wage if remote_any==0 [aweight=person_weight], d
sum wage if remote_any==1 & remote_primary==0 [aweight=person_weight], d
sum wage if remote_primary==1 [aweight=person_weight], d

* Graph % remote year by year
preserve
collapse (mean) remote_any remote_some remote_primary [aweight = person_weight], by(date)
graph twoway connected remote_any remote_some remote_primary date, title("Work-from-Home by Year")legend(order(1 "Any WFH" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Do above for each occupation and industry
levelsof occupation, local(occs)
foreach occ in `occs'{
	preserve
	keep if occupation=="`occ'"
	collapse (mean) remote_any remote_some remote_primary [aweight = person_weight], by(date)
	graph twoway connected remote_any remote_some remote_primary date, title("Work-from-Home by Year (`occ')")legend(order(1 "Any WFH" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
	graph close
	restore
}
levelsof industry, local(inds)
foreach ind in `inds'{
	preserve
	keep if industry=="`ind'"
	collapse (mean) remote_any remote_some remote_primary [aweight = person_weight], by(date)
	graph twoway connected remote_any remote_some remote_primary date, title("Work-from-Home by Year (`ind')")legend(order(1 "Any WFH" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
	graph close
	restore
}

* Graph % of total time remote year by year
label var cal_year "Year"
preserve
collapse (mean) remote_fraction [aweight=person_weight], by(date)
graph twoway connected remote_fraction date, ytitle("") title("% of time Working-from-Home") graphregion(fcolor(white))
graph close
restore

* Do above for each occupation and industry
foreach occ in `occs'{
	preserve
	keep if occupation=="`occ'"
	collapse (mean) remote_fraction [aweight=person_weight], by(date)
	graph twoway connected remote_fraction date, ytitle("") title("% of time Working-from-Home (`occ')") graphregion(fcolor(white))
	graph close
	restore
}
foreach ind in `inds'{
	preserve
	keep if industry=="`ind'"
	collapse (mean) remote_fraction [aweight=person_weight], by(date)
	graph twoway connected remote_fraction date, ytitle("") title("% of time Working-from-Homer (`ind')") graphregion(fcolor(white))
	graph close
	restore
}

* Graph Median Annual Earnings by remote status by year
preserve
gen monthly_earnings_remote_none = monthly_earnings if remote_any==0
gen monthly_earnings_remote_any = monthly_earnings if remote_any==1
gen monthly_earnings_remote_some = monthly_earnings if remote_some==1
gen monthly_earnings_remote_primary = monthly_earnings if remote_primary==1
collapse (median) monthly_earnings_remote_none monthly_earnings_remote_any monthly_earnings_remote_some monthly_earnings_remote_primary [aweight=person_weight], by(date)
graph twoway connected monthly_earnings_remote_none monthly_earnings_remote_some monthly_earnings_remote_primary date, title("Median Monthly Earnings") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Median Wage by remote status by year
preserve
gen wage_remote_none = wage if remote_any==0
gen wage_remote_any = wage if remote_any==1
gen wage_remote_some = wage if remote_some==1
gen wage_remote_primary = wage if remote_primary==1
collapse (median) wage_remote_none wage_remote_any wage_remote_some wage_remote_primary [aweight=person_weight], by(date)
graph twoway connected wage_remote_none wage_remote_some wage_remote_primary date, title("Median Hourly Wage") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Mean Weekly Hours by remote status by year
preserve
gen weekly_hours_remote_none = weekly_hours if remote_any==0
gen weekly_hours_remote_any = weekly_hours if remote_any==1
gen weekly_hours_remote_some = weekly_hours if remote_some==1
gen weekly_hours_remote_primary = weekly_hours if remote_primary==1
collapse (mean) weekly_hours_remote_none weekly_hours_remote_any weekly_hours_remote_some weekly_hours_remote_primary [aweight=person_weight], by(date)
graph twoway connected weekly_hours_remote_none weekly_hours_remote_some weekly_hours_remote_primary date, title("Avg. Weekly Hours") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Bachelor's and above % by remote status by year
preserve
gen college_degree_remote_none = bachelors + highered if remote_any==0
gen college_degree_remote_any = bachelors + highered if remote_any==1
gen college_degree_remote_some = bachelors + highered if remote_some==1
gen college_degree_remote_primary = bachelors + highered if remote_primary==1
collapse (mean) college_degree_remote_none college_degree_remote_any college_degree_remote_some college_degree_remote_primary [aweight=person_weight], by(date)
graph twoway connected college_degree_remote_none college_degree_remote_some college_degree_remote_primary date, title("Bachelor's Degree or Higher") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Female % by remote status by year
preserve
gen female_remote_none = female if remote_any==0
gen female_remote_any = female if remote_any==1
gen female_remote_some = female if remote_some==1
gen female_remote_primary = female if remote_primary==1
collapse (mean) female_remote_none female_remote_some female_remote_primary [aweight=person_weight], by(date)
graph twoway connected female_remote_none female_remote_some female_remote_primary date, title("% Female") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Find Top and Bottom Industries/Occupations
* 2-digit codes, Occupations, Full Sample
sort occupation_code_agg
by occupation_code_agg: egen remote_any_occ_mean = mean(remote_any)
by occupation_code_agg: egen remote_some_occ_mean = mean(remote_some)
by occupation_code_agg: egen remote_primary_occ_mean = mean(remote_primary)
order occupation, last

preserve
collapse remote_any_occ_mean remote_some_occ_mean remote_primary_occ_mean, by(occupation_code_agg occupation)
sort remote_any_occ_mean
sort remote_some_occ_mean
sort remote_primary_occ_mean
restore

* 2-digit codes, Industries, Full Sample
sort industry_code_agg
by industry_code_agg: egen remote_any_ind_mean = mean(remote_any)
by industry_code_agg: egen remote_some_ind_mean = mean(remote_some)
by industry_code_agg: egen remote_primary_ind_mean = mean(remote_primary)
order industry, last

preserve
collapse remote_any_ind_mean remote_some_ind_mean remote_primary_ind_mean, by(industry_code_agg industry)
sort remote_any_ind_mean
sort remote_some_ind_mean
sort remote_primary_ind_mean
restore

* 4-digit codes, Occupations, Full Sample
sort occupation_code
by occupation_code: egen remote_any_occ_spec_mean = mean(remote_any)
by occupation_code: egen occ_spec_count = count(remote_any)
by occupation_code: egen remote_some_occ_spec_mean = mean(remote_some)
by occupation_code: egen remote_primary_occ_spec_mean = mean(remote_primary)
order occupation_code, last

preserve
drop if occ_spec_count<30
collapse remote_any_occ_spec_mean remote_some_occ_spec_mean remote_primary_occ_spec_mean occ_spec_count, by(occupation_code)
sort remote_any_occ_spec_mean occ_spec_count occupation_code
sort remote_some_occ_spec_mean occ_spec_count occupation_code
sort remote_primary_occ_spec_mean occ_spec_count occupation_code
restore

* 4-digit codes, Industries, Full Sample
sort industry_code
by industry_code: egen remote_any_ind_spec_mean = mean(remote_any)
by industry_code: egen ind_spec_count = count(remote_any)
by industry_code: egen remote_some_ind_spec_mean = mean(remote_some)
by industry_code: egen remote_primary_ind_spec_mean = mean(remote_primary)
order industry_code, last

preserve
drop if ind_spec_count<30
collapse remote_any_ind_spec_mean remote_some_ind_spec_mean remote_primary_ind_spec_mean ind_spec_count, by(industry_code)
sort remote_any_ind_spec_mean ind_spec_count industry_code
sort remote_some_ind_spec_mean ind_spec_count industry_code
sort remote_primary_ind_spec_mean ind_spec_count industry_code
restore

* Find Industries/Occupations where changing to Remote was more likely
* 2-digit codes, Occupations, 18-20 Change
sort occupation_code_agg
forval y = 2018(1)2020{
	by occupation_code_agg: egen remote_any_occ_mean_`y' = mean(cond(cal_year == `y', remote_any, .))
	by occupation_code_agg: egen remote_some_occ_mean_`y' = mean(cond(cal_year == `y', remote_some, .))
	by occupation_code_agg: egen remote_primary_occ_mean_`y' = mean(cond(cal_year == `y', remote_primary, .))
	}
order occupation_code_agg occupation, last

gen remote_any_occ_mean_diff = remote_any_occ_mean_2020 - remote_any_occ_mean_2018
gen remote_some_occ_mean_diff = remote_some_occ_mean_2020 - remote_some_occ_mean_2018
gen remote_primary_occ_mean_diff = remote_primary_occ_mean_2020 - remote_primary_occ_mean_2018

preserve
collapse remote_any_occ_mean_diff remote_some_occ_mean_diff remote_primary_occ_mean_diff, by(occupation occupation_code_agg)
sort remote_any_occ_mean_diff
sort remote_some_occ_mean_diff
sort remote_primary_occ_mean_diff
restore

* 2-digit codes, Industries, 18-20 Change
sort industry_code_agg
forval y = 2018(1)2020{
	by industry_code_agg: egen remote_any_ind_mean_`y' = mean(cond(cal_year == `y', remote_any, .))
	by industry_code_agg: egen remote_some_ind_mean_`y' = mean(cond(cal_year == `y', remote_some, .))
	by industry_code_agg: egen remote_primary_ind_mean_`y' = mean(cond(cal_year == `y', remote_primary, .))
	}
order industry_code_agg industry, last

gen remote_any_ind_mean_diff = remote_any_ind_mean_2020 - remote_any_ind_mean_2018
gen remote_some_ind_mean_diff = remote_some_ind_mean_2020 - remote_some_ind_mean_2018
gen remote_primary_ind_mean_diff = remote_primary_ind_mean_2020 - remote_primary_ind_mean_2018

preserve
collapse remote_any_ind_mean_diff remote_some_ind_mean_diff remote_primary_ind_mean_diff, by(industry industry_code_agg)
sort remote_any_ind_mean_diff
sort remote_some_ind_mean_diff
sort remote_primary_ind_mean_diff
restore

* 4-digit codes, Occupations, 18-20 Change
sort occupation_code
forval y = 2018(1)2020{
	by occupation_code: egen remote_any_occ_spec_mean_`y' = mean(cond(cal_year == `y', remote_any, .))
	by occupation_code: egen remote_some_occ_spec_mean_`y' = mean(cond(cal_year == `y', remote_some, .))
	by occupation_code: egen remote_prim_occ_spec_mean_`y' = mean(cond(cal_year == `y', remote_primary, .))
	}
order occupation_code occupation, last

gen remote_any_occ_spec_mean_diff = remote_any_occ_spec_mean_2020 - remote_any_occ_spec_mean_2018
gen remote_some_occ_spec_mean_diff = remote_some_occ_spec_mean_2020 - remote_some_occ_spec_mean_2018
gen remote_prim_occ_spec_mean_diff = remote_prim_occ_spec_mean_2020 - remote_prim_occ_spec_mean_2018

preserve
drop if occ_spec_count<30
collapse remote_any_occ_spec_mean_diff remote_some_occ_spec_mean_diff remote_prim_occ_spec_mean_diff occ_spec_count, by(occupation_code)
sort remote_any_occ_spec_mean_diff occupation_code occ_spec_count
sort remote_some_occ_spec_mean_diff occupation_code occ_spec_count
sort remote_prim_occ_spec_mean_diff occupation_code occ_spec_count
restore

* 4-digit codes, Industries, 18-20 Change
sort industry_code
forval y = 2018(1)2020{
	by industry_code: egen remote_any_ind_spec_mean_`y' = mean(cond(cal_year == `y', remote_any, .))
	by industry_code: egen remote_some_ind_spec_mean_`y' = mean(cond(cal_year == `y', remote_some, .))
	by industry_code: egen remote_prim_ind_spec_mean_`y' = mean(cond(cal_year == `y', remote_primary, .))
	}
order industry_code industry, last

gen remote_any_ind_spec_mean_diff = remote_any_ind_spec_mean_2020 - remote_any_ind_spec_mean_2018
gen remote_some_ind_spec_mean_diff = remote_some_ind_spec_mean_2020 - remote_some_ind_spec_mean_2018
gen remote_prim_ind_spec_mean_diff = remote_prim_ind_spec_mean_2020 - remote_prim_ind_spec_mean_2018

*preserve
drop if ind_spec_count<30
collapse remote_any_ind_spec_mean_diff remote_some_ind_spec_mean_diff remote_prim_ind_spec_mean_diff ind_spec_count, by(industry_code)
sort remote_any_ind_spec_mean_diff industry_code ind_spec_count
sort remote_some_ind_spec_mean_diff industry_code ind_spec_count
sort remote_prim_ind_spec_mean_diff industry_code ind_spec_count
*restore

* Annual
use sipp_clean_annual, clear

label var annual_earnings "Annual Earnings"
label var wage "Wage"
label var remote_any "Any WFH"
label var remote_primary "Primarily WFH"
label var remote_some "Hybrid WFH"
label var days_remote "WFH Days per Week"
label var days_worked "Work Days per Week"
label var remote_fraction "Percent Days WFH"
label var weekly_hours "Weekly Hours"
label var age "Age"
label var female "Female"
label var hispanic "Hispanic"
label var black "Black"
label var asian "Asian"
label var hsdropout "High School Dropout"
label var hsgraduate "High School Graduate"
label var somecollege "Some College"
label var associates "Associate's Degree"
label var bachelors "Bachelor's Degree"
label var highered "Graduate Degree"

sum
sum [aweight=person_weight]

est clear
estpost tabstat annual_earnings wage remote_any remote_primary remote_some days_remote days_worked remote_fraction weekly_hours age female hispanic black asian hsdropout hsgraduate somecollege associates bachelors highered [aweight=person_weight], c(stat) stat(n mean sd min max)
esttab using "$tables\sum_stats_ann.tex", replace   ///
 cells("count(fmt(%9.3gc)) mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min max") nonumber /// 
 nomtitle nonote noobs label booktabs ///
 collabels("N" "Mean" "SD" "Min" "Max") ///
 prehead(`"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"' ///
         `"\begin{tabular}{l*{1}{ccccc}}"') ///
 postfoot(`"\end{tabular}"') ///
 title("Summary Stats (Annual)")

* Breakdown Summary Stats by Remote Status
sum if remote_any==0 [aweight=person_weight]
sum if remote_any==1 & remote_primary==0 [aweight=person_weight]
sum if remote_primary==1 [aweight=person_weight]

gen remote_status = 0
replace remote_status = 1 if remote_some==1
replace remote_status = 2 if remote_primary==1

est clear
estpost tabstat annual_earnings wage days_remote days_worked remote_fraction weekly_hours age female hispanic black asian hsdropout hsgraduate somecollege associates bachelors highered [aweight=person_weight], by(remote_status) c(stat) stat(mean) nototal
esttab using "$tables\sum_stats_by_remote_ann.tex", replace   ///
 main(mean %12.2fc) nostar nonumber unstack /// 
 compress nonote noobs gap label booktabs ///
 collabels(none) ///
 eqlabels("In Person" "Hybrid" "Primarily WFH") /// 
 prehead(`"\begin{tabular}{l*{3}{c}}"') ///
 postfoot(`"\end{tabular}"') ///
 nomtitles ///
 title("Summary Stats by Remote Status (Annual)")

sum annual_earnings if remote_any==0 [aweight=person_weight], d
sum annual_earnings if remote_any==1 & remote_primary==0 [aweight=person_weight], d
sum annual_earnings if remote_primary==1 [aweight=person_weight], d
sum wage if remote_any==0 [aweight=person_weight], d
sum wage if remote_any==1 & remote_primary==0 [aweight=person_weight], d
sum wage if remote_primary==1 [aweight=person_weight], d

* Graph % remote year by year
preserve
collapse (mean) remote_any remote_some remote_primary [aweight = person_weight], by(year)
graph twoway connected remote_any remote_some remote_primary year, title("Work-from-Home by Year")legend(order(1 "Any WFH" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph % of total time remote year by year
label var year "Year"
preserve
collapse (mean) remote_fraction [aweight=person_weight], by(year)
graph twoway connected remote_fraction year, ytitle("") title("% of time Working-from-Home") graphregion(fcolor(white))
graph close
restore

* Graph Median Annual Earnings by remote status by year
preserve
gen annual_earnings_remote_none = annual_earnings if remote_any==0
gen annual_earnings_remote_any = annual_earnings if remote_any==1
gen annual_earnings_remote_some = annual_earnings if remote_some==1
gen annual_earnings_remote_primary = annual_earnings if remote_primary==1
collapse (median) annual_earnings_remote_none annual_earnings_remote_any annual_earnings_remote_some annual_earnings_remote_primary [aweight=person_weight], by(year)
graph twoway connected annual_earnings_remote_none annual_earnings_remote_some annual_earnings_remote_primary year, title("Median Annual Earnings") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Median Wage by remote status by year
preserve
gen wage_remote_none = wage if remote_any==0
gen wage_remote_any = wage if remote_any==1
gen wage_remote_some = wage if remote_some==1
gen wage_remote_primary = wage if remote_primary==1
collapse (median) wage_remote_none wage_remote_any wage_remote_some wage_remote_primary [aweight=person_weight], by(year)
graph twoway connected wage_remote_none wage_remote_some wage_remote_primary year, title("Median Hourly Wage") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Mean Weekly Hours by remote status by year
preserve
gen weekly_hours_remote_none = weekly_hours if remote_any==0
gen weekly_hours_remote_any = weekly_hours if remote_any==1
gen weekly_hours_remote_some = weekly_hours if remote_some==1
gen weekly_hours_remote_primary = weekly_hours if remote_primary==1
collapse (mean) weekly_hours_remote_none weekly_hours_remote_any weekly_hours_remote_some weekly_hours_remote_primary [aweight=person_weight], by(year)
graph twoway connected weekly_hours_remote_none weekly_hours_remote_some weekly_hours_remote_primary year, title("Avg. Weekly Hours") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Bachelor's and above % by remote status by year
preserve
gen college_degree_remote_none = bachelors + highered if remote_any==0
gen college_degree_remote_any = bachelors + highered if remote_any==1
gen college_degree_remote_some = bachelors + highered if remote_some==1
gen college_degree_remote_primary = bachelors + highered if remote_primary==1
collapse (mean) college_degree_remote_none college_degree_remote_any college_degree_remote_some college_degree_remote_primary [aweight=person_weight], by(year)
graph twoway connected college_degree_remote_none college_degree_remote_some college_degree_remote_primary year, title("Bachelor's Degree or Higher") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore

* Graph Female % by remote status by year
preserve
gen female_remote_none = female if remote_any==0
gen female_remote_any = female if remote_any==1
gen female_remote_some = female if remote_some==1
gen female_remote_primary = female if remote_primary==1
collapse (mean) female_remote_none female_remote_some female_remote_primary [aweight=person_weight], by(year)
graph twoway connected female_remote_none female_remote_some female_remote_primary year, title("% Female") legend(order(1 "In-Person" 2 "Hybrid" 3 "Primarily WFH")) graphregion(fcolor(white))
graph close
restore