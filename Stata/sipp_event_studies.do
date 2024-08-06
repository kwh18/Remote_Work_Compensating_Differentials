set matsize 800

global tables ""

use sipp_clean, clear

** Identifying when a remote change occurs
sort person_id date

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
egen job_change_show_year = max(job_change_show), by(person_id cal_year)
gen job_change = job_change_show_year!=0 & job_change_show_year!=.
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
gen treat_any = date if remote_any_change==1
format treat_any %tm
egen edate_any = min(treat_any), by(person_id)
format edate_any %tm
gen switch_year_any = yofd(dofm(edate_any))
gen dist_from_edate_any = date - edate_any

* Remote Some
gen treat_some = date if remote_some_change==1
format treat_some %tm
egen edate_some = min(treat_some), by(person_id)
format edate_some %tm
gen switch_year_some = yofd(dofm(edate_some))
gen dist_from_edate_some = date - edate_some

* Remote Primary
gen treat_primary = date if remote_primary_change==1
format treat_primary %tm
egen edate_primary = min(treat_primary), by(person_id)
format edate_primary %tm
gen switch_year_primary = yofd(dofm(edate_primary))
gen dist_from_edate_primary = date - edate_primary


** Generating dummies indicating months away from switch

* Remote Any
forvalues k = 0/7 {
    gen g`k'_any = dist_from_edate_any == `k'
	label var g`k'_any "`k'"
	gen g_`k'_any = dist_from_edate_any == -`k'
	label var g_`k'_any "-`k'"
}
gen g8_any = dist_from_edate_any>=8 & !missing(dist_from_edate_any)
label var g8_any "8"
gen g_8_any = dist_from_edate_any<=-8
label var g_8_any "-8"

* Remote Some
forvalues k = 0/7 {
    gen g`k'_some = dist_from_edate_some == `k'
	label var g`k'_some "`k'"
	gen g_`k'_some = dist_from_edate_some == -`k'
	label var g_`k'_some "-`k'"
}
gen g8_some = dist_from_edate_some>=8 & !missing(dist_from_edate_some)
label var g8_some "8"
gen g_8_some = dist_from_edate_some<=-8
label var g_8_some "-8"

* Remote Primary
forvalues k = 0/7 {
    gen g`k'_primary = dist_from_edate_primary == `k'
	label var g`k'_primary "`k'"
	gen g_`k'_primary = dist_from_edate_primary == -`k'
	label var g_`k'_primary "-`k'"
}
gen g8_primary = dist_from_edate_primary>=8 & !missing(dist_from_edate_primary)
label var g8_primary "8"
gen g_8_primary = dist_from_edate_primary<=-8
label var g_8_primary "-8"


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
eventdd ln_wage age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_any) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_wages_remote_any.png", replace as(png)

* Earnings
eventdd ln_monthly_earnings age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_any) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_earnings_remote_any.png", replace as(png)

* Hours
eventdd ln_weekly_hours age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_any) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_hours_remote_any.png", replace as(png)

** Remote Some
* Drop remote primary individuals
preserve
drop if primary_drop==1

* Wage
eventdd ln_wage age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_some) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_wages_remote_some.png", replace as(png)

* Earnings
eventdd ln_monthly_earnings age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_some) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_earnings_remote_some.png", replace as(png)

* Hours
eventdd ln_weekly_hours age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_some) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Some)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_hours_remote_some.png", replace as(png)

** Remote Primary
* Drop remote some individuals
preserve
drop if some_drop==1

* Wage
eventdd ln_wage age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_primary) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_wages_remote_primary.png", replace as(png)

* Earnings
eventdd ln_monthly_earnings age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_primary) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_earnings_remote_primary.png", replace as(png)

* Hours
eventdd ln_weekly_hours age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_primary) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Naive Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
graph export "$tables\event_study_hours_remote_primary.png", replace as(png)


*** Event Studies (using Sun and Abraham (2020) Technique)
** Remote Any
* Wage
eventstudyinteract ln_wage g_8_any g_7_any g_6_any g_5_any g_4_any g_3_any g_2_any g0_any g1_any g2_any g3_any g4_any g5_any g6_any g7_any g8_any g_1_any, cohort(edate_any) control_cohort(control_any) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_wages_remote_any_SA.png", replace as(png)

* Earnings
eventstudyinteract ln_monthly_earnings g_8_any g_7_any g_6_any g_5_any g_4_any g_3_any g_2_any g0_any g1_any g2_any g3_any g4_any g5_any g6_any g7_any g8_any g_1_any, cohort(edate_any) control_cohort(control_any) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_earnings_remote_any_SA.png", replace as(png)

* Hours
eventstudyinteract ln_weekly_hours g_8_any g_7_any g_6_any g_5_any g_4_any g_3_any g_2_any g0_any g1_any g2_any g3_any g4_any g5_any g6_any g7_any g8_any g_1_any, cohort(edate_any) control_cohort(control_any) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Any)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_hours_remote_any_SA.png", replace as(png)


** Remote Some

* Drop remote primary individuals
preserve
drop if primary_drop==1

* Wage
eventstudyinteract ln_wage g_8_some g_7_some g_6_some g_5_some g_4_some g_3_some g_2_some g0_some g1_some g2_some g3_some g4_some g5_some g6_some g7_some g8_some g_1_some, cohort(edate_some) control_cohort(control_some) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Hybrid)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level. Primarily remote individuals are dropped}" "{stSerif:from the sample.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_wages_remote_some_SA.png", replace as(png)

* Earnings
eventstudyinteract ln_monthly_earnings g_8_some g_7_some g_6_some g_5_some g_4_some g_3_some g_2_some g0_some g1_some g2_some g3_some g4_some g5_some g6_some g7_some g8_some g_1_some, cohort(edate_some) control_cohort(control_some) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Hybrid)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level. Primarily remote individuals are dropped}" "{stSerif:from the sample.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_earnings_remote_some_SA.png", replace as(png)

* Hours
eventstudyinteract ln_weekly_hours g_8_some g_7_some g_6_some g_5_some g_4_some g_3_some g_2_some g0_some g1_some g2_some g3_some g4_some g5_some g6_some g7_some g8_some g_1_some, cohort(edate_some) control_cohort(control_some) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Hybrid)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level. Primarily remote individuals are dropped}" "{stSerif:from the sample.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_hours_remote_some_SA.png", replace as(png)

restore

** Remote Primary

* Drop remote some individuals
preserve
drop if some_drop==1

* Wage
eventstudyinteract ln_wage g_8_primary g_7_primary g_6_primary g_5_primary g_4_primary g_3_primary g_2_primary g0_primary g1_primary g2_primary g3_primary g4_primary g5_primary g6_primary g7_primary g8_primary g_1_primary, cohort(edate_primary) control_cohort(control_primary) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Wage at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level. Hybrid remote individuals are dropped}" "{stSerif:from the sample.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_wages_remote_primary_SA.png", replace as(png)

* Earnings
eventstudyinteract ln_monthly_earnings g_8_primary g_7_primary g_6_primary g_5_primary g_4_primary g_3_primary g_2_primary g0_primary g1_primary g2_primary g3_primary g4_primary g5_primary g6_primary g7_primary g8_primary g_1_primary, cohort(edate_primary) control_cohort(control_primary) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Earnings at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level. Hybrid remote individuals are dropped}" "{stSerif:from the sample.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_earnings_remote_primary_SA.png", replace as(png)

* Hours
eventstudyinteract ln_weekly_hours g_8_primary g_7_primary g_6_primary g_5_primary g_4_primary g_3_primary g_2_primary g0_primary g1_primary g2_primary g3_primary g4_primary g5_primary g6_primary g7_primary g8_primary g_1_primary, cohort(edate_primary) control_cohort(control_primary) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(i.date i.person_id) vce(cluster person_id)

matrix C = e(b_iw)
mata st_matrix("A",sqrt(st_matrix("e(V_iw)")))
matrix C = C \ A
matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
matrix list C
matrix list B

coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Hours at WFH Switch (Primary)}}", color(black) size(large)) xtitle("{stSerif:Months Since WFH Switch}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level. Hybrid remote individuals are dropped}" "{stSerif:from the sample.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
graph export "$tables\event_study_hours_remote_primary_SA.png", replace as(png)

restore
