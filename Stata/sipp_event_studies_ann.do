set matsize 800

global tables ""

use sipp_clean_annual, clear

** Identifying when a remote change occurs
sort person_id year

* Remote Any
by person_id: gen remote_any_change = d.remote_any
by person_id: egen control_any = max(remote_any)
replace control_any = 1 - control_any

* Remote Some
by person_id: gen remote_some_change = d.remote_some
by person_id: egen control_some = max(remote_some)
replace control_some = 1 - control_some

* Remote Primary
by person_id: gen remote_primary_change = d.remote_primary
by person_id: egen control_primary = max(remote_primary)
replace control_primary = 1 - control_primary

/* Identifying when job change occurs (with industry or occupation changes (4-digit))
by person_id: gen occ_change = d.occupation_code
by person_id: gen ind_change = d.industry_code
gen job_change = (occ_change>0 | ind_change>0)
gen remote_any_job_change = (job_change==1 & remote_any_change==1)
gen remote_some_job_change = (job_change==1 & remote_some_change==1)
gen remote_primary_job_change = (job_change==1 & remote_primary_change==1)
by person_id: egen simult_job_any = max(remote_any_job_change)
by person_id: egen simult_job_some = max(remote_some_job_change)
by person_id: egen simult_job_primary = max(remote_primary_job_change)
*/
* Identifying when job change occurs (with jobid variable)
gen job_change_show = d.jobid_1
gen job_change = job_change_show!=0 & job_change_show!=.
gen remote_any_job_change = (job_change==1 & remote_any_change==1)
gen remote_some_job_change = (job_change==1 & remote_some_change==1)
gen remote_primary_job_change = (job_change==1 & remote_primary_change==1)
egen simult_job_any = max(remote_any_job_change), by(person_id)
egen simult_job_some = max(remote_some_job_change), by(person_id)
egen simult_job_primary = max(remote_primary_job_change), by(person_id)

* Dropping those that only change to remote because of changning job
drop if simult_job_any==1 | simult_job_some==1 | simult_job_primary==1

** Reorgranizing as distance from change
* Remote Any
gen treat_any = year if remote_any_change==1
format treat_any %tm
egen eyear_any = min(treat_any), by(person_id)
format eyear_any %tm
gen dist_from_eyear_any = year - eyear_any

* Remote Some
gen treat_some = year if remote_some_change==1
format treat_some %tm
egen eyear_some = min(treat_some), by(person_id)
format eyear_some %tm
gen dist_from_eyear_some = year - eyear_some

* Remote Primary
gen treat_primary = year if remote_primary_change==1
format treat_primary %tm
egen eyear_primary = min(treat_primary), by(person_id)
format eyear_primary %tm
gen switch_year_primary = yofd(dofm(eyear_primary))
gen dist_from_eyear_primary = year - eyear_primary


** Generating dummies indicating months away from switch

* Remote Any
forvalues k = 0/1 {
    gen g`k'_any = dist_from_eyear_any == `k'
	label var g`k'_any "`k'"
	gen g_`k'_any = dist_from_eyear_any == -`k'
	label var g_`k'_any "-`k'"
}
gen g2_any = dist_from_eyear_any>=2 & !missing(dist_from_eyear_any)
label var g2_any "2"
gen g_2_any = dist_from_eyear_any<=-2
label var g_2_any "-2"

* Remote Some
forvalues k = 0/1 {
    gen g`k'_some = dist_from_eyear_some == `k'
	label var g`k'_some "`k'"
	gen g_`k'_some = dist_from_eyear_some == -`k'
	label var g_`k'_some "-`k'"
}
gen g2_some = dist_from_eyear_some>=2 & !missing(dist_from_eyear_some)
label var g2_some "2"
gen g_2_some = dist_from_eyear_some<=-2
label var g_2_some "-2"

* Remote Primary
forvalues k = 0/1 {
    gen g`k'_primary = dist_from_eyear_primary == `k'
	label var g`k'_primary "`k'"
	gen g_`k'_primary = dist_from_eyear_primary == -`k'
	label var g_`k'_primary "-`k'"
}
gen g2_primary = dist_from_eyear_primary>=2 & !missing(dist_from_eyear_primary)
label var g2_primary "2"
gen g_2_primary = dist_from_eyear_primary<=-2
label var g_2_primary "-2"


** Create drop indics for comparisons
by person_id: egen some_drop = max(remote_some)
by person_id: egen primary_drop = max(remote_primary)

by person_id: egen min_emp_status = min(emp_status)

by person_id: egen min_occ = min(occupation_code)
by person_id: egen max_occ = max(occupation_code)
by person_id: egen min_ind = min(industry_code)
by person_id: egen max_ind = max(industry_code)

*** Event Studies (using Naive Technique)
** Remote Any
* Wage
eventdd ln_wage age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_any) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_wages_remote_any_ann.png", replace as(png)

* Earnings
eventdd ln_monthly_earnings age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_any) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_earnings_remote_any_ann.png", replace as(png)

* Hours
eventdd ln_weekly_hours age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_any) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_hours_remote_any_ann.png", replace as(png)

** Remote Some
* Drop remote primary individuals
preserve
drop if primary_drop==1

* Wage
eventdd ln_wage age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_some) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_wages_remote_some_ann.png", replace as(png)

* Earnings
eventdd ln_monthly_earnings age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_some) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_earnings_remote_some_ann.png", replace as(png)

* Hours
eventdd ln_weekly_hours age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_some) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_hours_remote_some_ann.png", replace as(png)

** Remote Primary
* Drop remote some individuals
preserve
drop if some_drop==1

* Wage
eventdd ln_wage age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_primary) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_wages_remote_primary_ann.png", replace as(png)

* Earnings
eventdd ln_monthly_earnings age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_primary) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_earnings_remote_primary_ann.png", replace as(png)

* Hours
eventdd ln_weekly_hours age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.year, timevar(dist_from_eyear_primary) accum leads(2) lags(2) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_hours_remote_primary_ann.png", replace as(png)


*** Event Studies (using Sun and Abraham (2020) Technique)
** Remote Any
* Wage
eventstudyinteract ln_wage g_2_any g0_any g1_any g2_any g_1_any, cohort(eyear_any) control_cohort(control_any) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_wages_remote_any_ann_SA.png", replace as(png)

* Earnings
eventstudyinteract ln_annual_earnings g_2_any g0_any g1_any g2_any g_1_any, cohort(eyear_any) control_cohort(control_any) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_earnings_remote_any_ann_SA.png", replace as(png)

* Hours
eventstudyinteract ln_weekly_hours g_2_any g0_any g1_any g2_any g_1_any, cohort(eyear_any) control_cohort(control_any) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_hours_remote_any_ann_SA.png", replace as(png)


** Remote Some

* Drop remote primary individuals
preserve
drop if primary_drop==1

* Wage
eventstudyinteract ln_wage g_2_some g0_some g1_some g2_some g_1_some, cohort(eyear_some) control_cohort(control_some) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_wages_remote_some_ann_SA.png", replace as(png)

* Earnings
eventstudyinteract ln_annual_earnings g_2_some g0_some g1_some g2_some g_1_some, cohort(eyear_some) control_cohort(control_some) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_earnings_remote_some_ann_SA.png", replace as(png)

* Hours
eventstudyinteract ln_weekly_hours g_2_some g0_some g1_some g2_some g_1_some, cohort(eyear_some) control_cohort(control_some) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_hours_remote_some_ann_SA.png", replace as(png)

restore

** Remote Primary

* Drop remote some individuals
preserve
drop if some_drop==1

* Wage
eventstudyinteract ln_wage g_2_primary g0_primary g1_primary g2_primary g_1_primary, cohort(eyear_primary) control_cohort(control_primary) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_wages_remote_primary_ann_SA.png", replace as(png)

* Earnings
eventstudyinteract ln_annual_earnings g_2_primary g0_primary g1_primary g2_primary g_1_primary, cohort(eyear_primary) control_cohort(control_primary) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_earnings_remote_primary_ann_SA.png", replace as(png)

* Hours
eventstudyinteract ln_weekly_hours g_2_primary g0_primary g1_primary g2_primary g_1_primary, cohort(eyear_primary) control_cohort(control_primary) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.year i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..1] , C[.,5..5], C[.,2..4])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Years Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Year and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(2, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_hours_remote_primary_ann_SA.png", replace as(png)

restore
