
global tables ""

use sipp_clean_keep_ue, clear

** Identifying when an employment status change occurs
sort person_id date

gen emp_status_change = d.emp_status
gen ue_to_e = (emp_status_change==1)
gen e_to_ue = (emp_status_change==-1)
egen ue_to_e_id = max(ue_to_e), by(person_id)
egen e_to_ue_id = max(e_to_ue), by(person_id)

gen e_to_e_id = (ue_to_e_id==0 & e_to_ue_id==0 & emp_status==1)
gen ue_to_ue_id = (ue_to_e_id==0 & e_to_ue_id==0 & emp_status==0)
gen control_e_to_ue = 1 - e_to_ue_id
gen control_ue_to_e = 1 - ue_to_e_id
gen control = (control_e_to_ue==1 & control_ue_to_e==1)

// Identifying when job change occurs (with industry or occupation changes (4-digit))
// by person_id: gen occ_change = d.occupation_code
// by person_id: gen ind_change = d.industry_code
// gen job_change = (occ_change>0 | ind_change>0)
// gen remote_any_job_change = (job_change==1 & remote_any_change==1)
// gen remote_some_job_change = (job_change==1 & remote_some_change==1)
// gen remote_primary_job_change = (job_change==1 & remote_primary_change==1)
// by person_id: egen simult_job_any = max(remote_any_job_change)
// by person_id: egen simult_job_some = max(remote_some_job_change)
// by person_id: egen simult_job_primary = max(remote_primary_job_change)
//
// * Identifying when job change occurs (with jobid variable) at same time as remote change
// gen job_change_show = d.jobid_1
// egen job_change_show_year = max(job_change_show), by(person_id cal_year)
// gen job_change = job_change_show_year!=0 & job_change_show_year!=.
// gen remote_any_job_change = (job_change==1 & remote_any_change==1)
// gen remote_some_job_change = (job_change==1 & remote_some_change==1)
// gen remote_primary_job_change = (job_change==1 & remote_primary_change==1)
// egen simult_job_any = max(remote_any_job_change), by(person_id)
// egen simult_job_some = max(remote_some_job_change), by(person_id)
// egen simult_job_primary = max(remote_primary_job_change), by(person_id)
//
// * Dropping those that only change to remote because of changing job
// drop if simult_job_any==1 | simult_job_some==1 | simult_job_primary==1
//
// * Identifying when employment status change occurs (with emp_status variable) at same time as remote change
// gen emp_status_change_show = d.emp_status
// egen emp_status_change_show_year = max(emp_status_change_show), by(person_id cal_year)
// gen emp_status_change = emp_status_change_show_year!=0 & emp_status_change_show_year!=.
// gen remote_any_emp_status_change = (emp_status_change==1 & remote_any_change==1)
// gen remote_some_emp_status_change = (emp_status_change==1 & remote_some_change==1)
// gen remote_primary_emp_status_change = (emp_status_change==1 & remote_primary_change==1)
// egen simult_emp_status_any = max(remote_any_emp_status_change), by(person_id)
// egen simult_emp_status_some = max(remote_some_emp_status_change), by(person_id)
// egen simult_emp_status_primary = max(remote_primary_emp_status_change), by(person_id)
//
// * Dropping those that only change to remote because of changing employment status
// drop if simult_emp_status_any==1 | simult_emp_status_some==1 | simult_emp_status_primary==1

** Reorgranizing as distance from change
* UE to E
gen treat_ue_to_e = date if ue_to_e==1
format treat_ue_to_e %tm
egen edate_ue_to_e = min(treat_ue_to_e), by(person_id)
format edate_ue_to_e %tm
gen switch_year_ue_to_e = yofd(dofm(edate_ue_to_e))
gen dist_from_edate_ue_to_e = date - edate_ue_to_e

* E to UE
gen treat_e_to_ue = date if e_to_ue==1
format treat_e_to_ue %tm
egen edate_e_to_ue = min(treat_e_to_ue), by(person_id)
format edate_e_to_ue %tm
gen switch_year_e_to_ue = yofd(dofm(edate_e_to_ue))
gen dist_from_edate_e_to_ue = date - edate_e_to_ue

** Generating dummies indicating months away from switch

* UE to E
forvalues k = 0/7 {
    gen g`k'_ue_to_e = dist_from_edate_ue_to_e == `k'
	label var g`k'_ue_to_e "`k'"
	gen g_`k'_ue_to_e = dist_from_edate_ue_to_e == -`k'
	label var g_`k'_ue_to_e "-`k'"
}
gen g8_ue_to_e = dist_from_edate_ue_to_e>=8 & !missing(dist_from_edate_ue_to_e)
label var g8_ue_to_e "8"
gen g_8_ue_to_e = dist_from_edate_ue_to_e<=-8
label var g_8_ue_to_e "-8"

* E to UE
forvalues k = 0/7 {
    gen g`k'_e_to_ue = dist_from_edate_e_to_ue == `k'
	label var g`k'_e_to_ue "`k'"
	gen g_`k'_e_to_ue = dist_from_edate_e_to_ue == -`k'
	label var g_`k'_e_to_ue "-`k'"
}
gen g8_e_to_ue = dist_from_edate_e_to_ue>=8 & !missing(dist_from_edate_e_to_ue)
label var g8_e_to_ue "8"
gen g_8_e_to_ue = dist_from_edate_e_to_ue<=-8
label var g_8_e_to_ue "-8"


** Create drop indics for comparisons
by person_id: egen any_id = max(remote_any)
by person_id: egen some_id = max(remote_some)
by person_id: egen primary_id = max(remote_primary)
gen none_id = 1 - any_id

gen unemp_status = 1-emp_status

// * Attempting to put multiple event studies on one graph
// preserve
// keep if inrange(dist_from_edate_e_to_ue, -8, 8)
// egen emp_status_any_e_to_ue_mean = mean(emp_status), by(remote_any dist_from_edate_e_to_ue)
// egen emp_status_any_e_to_ue_sd = sd(emp_status), by(remote_any dist_from_edate_e_to_ue)
//
// egen emp_status_any_e_to_ue_tag = tag(remote_any dist_from_edate_e_to_ue)
//
// gen date2 = cond(remote_any==1, dist_from_edate_e_to_ue - 0.1, dist_from_edate_e_to_ue + 0.1)
//
// gen upper = emp_status_any_e_to_ue_mean + emp_status_any_e_to_ue_sd
// gen lower = emp_status_any_e_to_ue_mean - emp_status_any_e_to_ue_sd
// set scheme s1color
//
// twoway rcap upper lower date2 if emp_status_any_e_to_ue_tag & remote_any == 1, lc(red) || scatter emp_status_any_e_to_ue_mean date2 if emp_status_any_e_to_ue_tag & remote_any == 1, mc(red) ///
// || rcap upper lower date2 if emp_status_any_e_to_ue_tag & remote_any == 0, lc(blue) || scatter emp_status_any_e_to_ue_mean date2 if emp_status_any_e_to_ue_tag & remote_any == 0, mc(blue) ///
// legend(order(2 "Remote" 4 "Not Remote")) xtitle("") xla(-8/8) ytitle(Mean and SD of Employment Status)
//
// twoway line emp_status_any_e_to_ue_mean dist_from_edate_e_to_ue if emp_status_any_e_to_ue_tag & remote_any == 1, mc(red) ///
// || line emp_status_any_e_to_ue_mean dist_from_edate_e_to_ue if emp_status_any_e_to_ue_tag & remote_any == 0, mc(blue) ///
// legend(order(1 "Remote" 2 "Not Remote")) xtitle("") xla(-8/8) ytitle(Mean Employment Status)
// restore 

// *** Event Studies (using Naive Technique)
// ** UE to E
// eventdd emp_status age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_ue_to_e) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{bf:Figure X. {it:Trends in Employment at Employment Date}}}", color(black) size(large)) xtitle("{stSerif:Months Since UE to E}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
// graph export "$tables\event_study_emp_ue_to_e.png", replace as(png)
//
// ** E to UE
// eventdd emp_status age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg i.date, timevar(dist_from_edate_e_to_ue) accum leads(8) lags(8) cluster(person_id) graph_op(legend(off) title( "{stSerif:{bf:Figure X. {it:Trends in Employment at Unemployment Date}}}", color(black) size(large)) xtitle("{stSerif:Months Since E to UE}") xscale(titlegap(2)) note("{stSerif:{it:Notes}. Event Study technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black))
// graph export "$tables\event_study_emp_e_to_ue.png", replace as(png)
//
// *** Event Studies (using Sun and Abraham (2020) Technique)
//
// ** UE to E
// * Employment
// eventstudyinteract emp_status g_8_ue_to_e g_7_ue_to_e g_6_ue_to_e g_5_ue_to_e g_4_ue_to_e g_3_ue_to_e g_2_ue_to_e g0_ue_to_e g1_ue_to_e g2_ue_to_e g3_ue_to_e g4_ue_to_e g5_ue_to_e g6_ue_to_e g7_ue_to_e g8_ue_to_e g_1_ue_to_e, cohort(edate_ue_to_e) control_cohort(control) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B
//
// coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Employment at Employment Date}}", color(black) size(large)) xtitle("{stSerif:Months Since UE to E}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
// graph export "$tables\event_study_emp_ue_to_e_SA.png", replace as(png)
//
// ** E to UE
// * Employment
// eventstudyinteract emp_status g_8_e_to_ue g_7_e_to_ue g_6_e_to_ue g_5_e_to_ue g_4_e_to_ue g_3_e_to_ue g_2_e_to_ue g0_e_to_ue g1_e_to_ue g2_e_to_ue g3_e_to_ue g4_e_to_ue g5_e_to_ue g6_e_to_ue g7_e_to_ue g8_e_to_ue g_1_e_to_ue, cohort(edate_e_to_ue) control_cohort(control_e_to_ue) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B
//
// coefplot matrix(B[1]), vertical se(B[2]) ciopts(recast(rcap)) legend(off) title( "{stSerif:{it:Trends in Employment at Unemployment Date}}", color(black) size(large)) xtitle("{stSerif:Months Since E to UE}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
// graph export "$tables\event_study_emp_e_to_ue_SA.png", replace as(png)
//
// * By Remote Status
// * Creating cohorts of remote status
// gen ue_to_e_any_id = ue_to_e_id * any_id
// gen ue_to_e_some_id = ue_to_e_id * some_id
// gen ue_to_e_primary_id = ue_to_e_id * primary_id
// gen ue_to_e_none_id = ue_to_e_id * none_id
// gen e_to_ue_any_id = e_to_ue_id * any_id
// gen e_to_ue_some_id = e_to_ue_id * some_id
// gen e_to_ue_primary_id = e_to_ue_id * primary_id
// gen e_to_ue_none_id = e_to_ue_id * none_id
//
// ** UE to E
// * Employment
// * Remote Any
// eventstudyinteract emp_status g_8_ue_to_e g_7_ue_to_e g_6_ue_to_e g_5_ue_to_e g_4_ue_to_e g_3_ue_to_e g_2_ue_to_e g0_ue_to_e g1_ue_to_e g2_ue_to_e g3_ue_to_e g4_ue_to_e g5_ue_to_e g6_ue_to_e g7_ue_to_e g8_ue_to_e g_1_ue_to_e, cohort(ue_to_e_any_id) control_cohort(control_ue_to_e) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_any = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_any
//
// * Remote Some
// eventstudyinteract emp_status g_8_ue_to_e g_7_ue_to_e g_6_ue_to_e g_5_ue_to_e g_4_ue_to_e g_3_ue_to_e g_2_ue_to_e g0_ue_to_e g1_ue_to_e g2_ue_to_e g3_ue_to_e g4_ue_to_e g5_ue_to_e g6_ue_to_e g7_ue_to_e g8_ue_to_e g_1_ue_to_e, cohort(ue_to_e_some_id) control_cohort(control_ue_to_e) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_some = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_some
//
// * Remote Primary
// eventstudyinteract emp_status g_8_ue_to_e g_7_ue_to_e g_6_ue_to_e g_5_ue_to_e g_4_ue_to_e g_3_ue_to_e g_2_ue_to_e g0_ue_to_e g1_ue_to_e g2_ue_to_e g3_ue_to_e g4_ue_to_e g5_ue_to_e g6_ue_to_e g7_ue_to_e g8_ue_to_e g_1_ue_to_e, cohort(ue_to_e_primary_id) control_cohort(control_ue_to_e) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_primary = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_primary
//
// * Remote None
// eventstudyinteract emp_status g_8_ue_to_e g_7_ue_to_e g_6_ue_to_e g_5_ue_to_e g_4_ue_to_e g_3_ue_to_e g_2_ue_to_e g0_ue_to_e g1_ue_to_e g2_ue_to_e g3_ue_to_e g4_ue_to_e g5_ue_to_e g6_ue_to_e g7_ue_to_e g8_ue_to_e g_1_ue_to_e, cohort(ue_to_e_none_id) control_cohort(control_ue_to_e) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_none = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_none
//
// coefplot (matrix(B_any[1]), se(B_any[2])) (matrix(B_some[1]), se(B_some[2])) (matrix(B_primary[1]), se(B_primary[2])) (matrix(B_none[1]), se(B_none[2])), vertical legend(off) ciopts(recast(rcap)) title( "{stSerif:{it:Trends in Employment at Employment Date}}", color(black) size(large)) xtitle("{stSerif:Months Since UE to E}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
// graph export "$tables\event_study_emp_ue_to_e_remote_SA.png", replace as(png)
//
// ** E to UE
// * Employment
// * Remote Any
// eventstudyinteract emp_status g_8_e_to_ue g_7_e_to_ue g_6_e_to_ue g_5_e_to_ue g_4_e_to_ue g_3_e_to_ue g_2_e_to_ue g0_e_to_ue g1_e_to_ue g2_e_to_ue g3_e_to_ue g4_e_to_ue g5_e_to_ue g6_e_to_ue g7_e_to_ue g8_e_to_ue g_1_e_to_ue, cohort(e_to_ue_any_id) control_cohort(control_e_to_ue) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_any = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_any
//
// * Remote Some
// eventstudyinteract emp_status g_8_e_to_ue g_7_e_to_ue g_6_e_to_ue g_5_e_to_ue g_4_e_to_ue g_3_e_to_ue g_2_e_to_ue g0_e_to_ue g1_e_to_ue g2_e_to_ue g3_e_to_ue g4_e_to_ue g5_e_to_ue g6_e_to_ue g7_e_to_ue g8_e_to_ue g_1_e_to_ue, cohort(e_to_ue_some_id) control_cohort(control_e_to_ue) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_some = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_some
//
// * Remote Primary
// eventstudyinteract emp_status g_8_e_to_ue g_7_e_to_ue g_6_e_to_ue g_5_e_to_ue g_4_e_to_ue g_3_e_to_ue g_2_e_to_ue g0_e_to_ue g1_e_to_ue g2_e_to_ue g3_e_to_ue g4_e_to_ue g5_e_to_ue g6_e_to_ue g7_e_to_ue g8_e_to_ue g_1_e_to_ue, cohort(e_to_ue_primary_id) control_cohort(control_e_to_ue) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_primary = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_primary
//
// * Remote None
// eventstudyinteract emp_status g_8_e_to_ue g_7_e_to_ue g_6_e_to_ue g_5_e_to_ue g_4_e_to_ue g_3_e_to_ue g_2_e_to_ue g0_e_to_ue g1_e_to_ue g2_e_to_ue g3_e_to_ue g4_e_to_ue g5_e_to_ue g6_e_to_ue g7_e_to_ue g8_e_to_ue g_1_e_to_ue, cohort(e_to_ue_none_id) control_cohort(control_e_to_ue) covariates(age age_sq i.state_code weekly_hours female hispanic black asian resid_race hsgraduate somecollege associates bachelors highered i.household_relationship i.worker_class i.industry_code_agg i.occupation_code_agg) absorb(date person_id) vce(cluster person_id)
//
// matrix C = e(b_iw)
// mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
// matrix C = C \ A'
// matrix B_none = (C[.,1..7] , C[.,17..17], C[.,8..16])
// matrix list C
// matrix list B_none
//
// coefplot (matrix(B_any[1]), se(B_any[2])) (matrix(B_some[1]), se(B_some[2])) (matrix(B_primary[1]), se(B_primary[2])) (matrix(B_none[1]), se(B_none[2])), vertical legend(off) ciopts(recast(rcap)) title( "{stSerif:{it:Trends in Employment at Unemployment Date}}", color(black) size(large)) xtitle("{stSerif:Months Since E to UE}") note("{stSerif:{it:Notes}. Sun and Abraham (2020) technique used. Controls include age, age^2, state of residence, weekly hours,}" "{stSerif:gender, race, education, household relationship, worker class, industry and occupation. Date and individual}" "{stSerif:fixed effects included. Errors are clustered at the individual level.}", margin(small)) xscale(titlegap(2)) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) mcolor(black) xline(8, lcolor(black) lwidth(thin)) yline(0)
// graph export "$tables\event_study_emp_e_to_ue_remote_SA.png", replace as(png)
//
