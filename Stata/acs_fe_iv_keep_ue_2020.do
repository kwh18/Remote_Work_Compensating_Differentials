

* Yearly Sample
use acs_clean_keep_ue, clear


* Merge in OxCGRT stringency index
drop if year<2018
sort serial pernum year
merge m:1 year state using stringency_yearly
drop if _merge==2
*replace stringency_index=0 if stringency_index==. & year!=2021
*drop if stringency_index==. & year==2021
drop if stringency_index==.

gen iv_interact = stringency_index * DN_class_agg

* Cluster IVs
egen clust_iv = group(year statefip)
egen clust_iv2 = group(year statefip occ_agg)

gen ln_incwage = ln(incwage)
rename wfh remote_primary

* Remote Primary
* Earnings
est clear

* Counting Obs and Groups
xtreg remote_primary incwage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

xtreg remote_primary incwage, fe cluster(person_id)
local depvar "`e(depvar)'"
rename `depvar' holding
gen `depvar'= e(N_clust) in 1
eststo: mean `depvar'
drop `depvar'
rename holding `depvar'

* OLS
eststo: reg ln_incwage remote_primary age age_sq i.relate i.classwkrd i.occ_agg i.ind_agg i.statefip uhrswork i.year i.sex i.race i.educd [aweight=perwt], r

* Fixed Effects
eststo: reghdfe ln_incwage remote_primary age age_sq i.relate i.classwkrd i.occ_agg i.ind_agg i.statefip uhrswork i.year i.sex i.race i.educd [aweight=perwt], absorb(person_id year) vce(robust)

* IV
eststo: ivregress 2sls ln_incwage age age_sq i.relate i.classwkrd i.occ_agg i.ind_agg i.statefip uhrswork i.year i.sex i.race i.educd (remote_primary = stringency_index) [aweight=perwt], vce(cluster clust_iv)

* IV2
eststo: ivregress 2sls ln_incwage age age_sq i.relate i.classwkrd i.occ_agg i.ind_agg i.statefip uhrswork i.year i.sex i.race i.educd (remote_primary = iv_interact) [aweight=perwt], vce(cluster clust_iv2)

esttab using "$tables\ACS_ann_keep_ue_2020.tex", append f ///
 b(%9.3gc) se(3) star(* 0.10 ** 0.05 *** 0.01)  /// 
 keep(remote_primary) varlabels(remote_primary "ACS - Remote Work (Primary)", elist(remote_primary \bottomrule)) ///
 label booktabs collabels(none) nomtitles nolines nonum noobs ///
 substitute([htbp] [!htbp] \begin{tabular} \small\begin{tabular} {l} {p{\linewidth}}) ///
 addnotes("Sample: 2020-2021. Annual observations of prime-age individuals employed at some point in the last two years. Individual outliers in 1st and outside of 99th percentile of average monthly earnings are dropped from sample. Since ACS does not classify hybrid individuals, nobody is dropped" ///
 "Models: Ordinary Least Squares (OLS), Individual-Month Fixed Effects (FE), Two Stage Least Squares with OxCGRT Stringency Index instrumenting remote work (IV), Two Stage Least Squares with the interaction of the OxCGRT Stringency Index and the Dingel-Niemann 2-digit occupation-level teleworkability instrumenting remote work (IV2)") ///
 alignment(D{.}{.}{-1}) sfmt(%6.0fc)