/*
 Codeshare Alliance between JetBlue and American Airlines written by Zheyu Ni 
at The Ohio State University, 3/7/2024
This file estimates the impact of NEA on price dispersion.
*/
///////////////////////////////////////////////////////////////////////////////
/// import the data, cleaned in Python

clear all
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\Cleaned_2019_2023_without_delete_small_market_dispersion.csv"

/// rename the columns
rename v8 MktFare_v
rename v9 MktFare_q1
rename v10 MktFare_q9

/// delete the first row
gen row_i = _n
drop if row_i==1
drop row_i

/// start analysis!

destring mktfare, replace
destring MktFare_v, replace
destring MktFare_q1 MktFare_q9, replace
destring roundtrip mktdistance nonstop passengers, replace


/// a mistake in the cleaned file where nea_market_codeshared = nea_market
egen nea_market2 = total(nea_market_codeshared), by(market)
replace nea_market = nea_market2
drop nea_market2

///drop if MktFare_v==0
///drop if MktFare_q1~=0
///drop if MktFare_q9==0
/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

gen zerosta = MktFare_q1==0
sum zerosta
drop zerosta  // around 19% market only have one flight. 


sum mktfare MktFare_v MktFare_q1 MktFare_q9 nea_market

gen dt = yq(year, quarter)
gen mktdistance2 = mktdistance^2
gen lnMktFare_q1 = ln(MktFare_q1)
gen lnMktFare_q9 = ln(MktFare_q9)

gen MktFare_sd=sqrt(MktFare_v)
gen mktdistance100 = mktdistance/100
gen mktdistance1002=mktdistance100^2

reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]
est sto reg1_v

reg lnMktFare_q1 roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]
est sto reg1_q1

reg lnMktFare_q9 roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]
est sto reg1_q9

drop if total_quantity <1000
egen newidd = group(market)
set matsize 4200
reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002 ///
 nea_market_codeshared i.newidd [aweight = passengers]
est sto reg1_v_market_fixed

estout reg1_v reg1_q1 reg1_q9 using result333.xls, cells("b" se)  replace
estout reg1_v_market_fixed  using result333_fixed.xls, cells("b" se)  replace
/// market fixed effects

reg lnMktFare_q9 roundtrip nonstop mktdistance mktdistance2 ///
nea_market nea_market_codeshared i.dt [aweight = passengers]

///////////////////////////////////////////////////////////////////////////////
/// import the data, cleaned in Python

clear all
import delimited "F:\Codeshare JetBlue AA\pythonProject3\Cleaned_2019_2023_without_delete_small_market315_carrier_route.csv"
/// carrier route level
/// rename the columns
rename v13 MktFare_v
rename v14 q1
rename v15 q05
rename v16 q10
rename v17 q15
rename v18 q20
rename v19 q25
rename v20 q30
rename v21 q35
rename v22 q40
rename v23 q45
rename v24 q50
rename v25 q55
rename v26 q60
rename v27 q65
rename v28 q70
rename v29 q75
rename v30 q80
rename v31 q85
rename v32 q90
rename v33 q99


/// delete the first row
gen row_i = _n
drop if row_i==1
drop row_i


destring mktfare, replace
destring MktFare_v, replace
destring q1 q05 q10 q15 q20 q25 q30 q35 q40 q45 q50 q55 q60 ///
q65 q70 q75 q80 q85 q90 q99, replace
destring mktdistance passengers, replace
egen nea_market = total(nea_market_codeshared), by(market)

save "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_315.dta", replace

clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_315.dta"

foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(ticketcarrier, "`x'")>0
}

gen dt = yq(year, quarter)
gen MktFare_sd=sqrt(MktFare_v)
gen mktdistance100 = mktdistance/100
gen mktdistance1002=mktdistance100^2
/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

********************************************************************************
///////////////////////////////////////////////////////////////////////////////
/// regression of market fare
/// N = 5017166
gen lnmktfare = ln(mktfare)

reg mktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
[aweight = passengers], cluster(market) 
est store reg_nocovid

reg lnmktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
[aweight = passengers], cluster(market) 
est store reg_nocovid_ln

/// seperate b6 and aa
gen nea_market_codeshared_b6 = nea_market_codeshared* B6
gen nea_market_codeshared_aa = nea_market_codeshared* AA

reg mktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared_b6 nea_market_codeshared_aa ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
[aweight = passengers], cluster(market) 

est store reg_b6aa_nocovid

reg lnmktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared_b6 nea_market_codeshared_aa ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
[aweight = passengers], cluster(market) 

est store reg_b6aa_nocovid_ln

/// delete samll markets 

egen total_quantity = total( passengers), by(market year quarter)

drop if total_quantity<2000
/// N= 752010, may need robostness check here
egen newidd = group(market) ///1957 markets left

set matsize 2200


reg lnmktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared i.dt i.newidd  WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
[aweight = passengers], cluster(market) 

est sto reg_market_fixed_nocovid_ln

reg lnmktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared_b6 nea_market_codeshared_aa ///
nea_market_codeshared i.dt i.newidd  WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
[aweight = passengers], cluster(market) 

est sto reg_market_fixed_b6aa_ln


estout reg_nocovid reg_nocovid_ln reg_b6aa_nocovid reg_b6aa_nocovid_ln  ///
 reg_market_fixed_nocovid_ln reg_market_fixed_b6aa_ln using ///
 result3152_marketfixed_nocovid.xls, cells("b" se)  replace
 
 
est restore reg_nocovid
ereturn list
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg_nocovid_ln
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg_b6aa_nocovid
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg_b6aa_nocovid_ln
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg_market_fixed_nocovid_ln
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg_market_fixed_b6aa_ln
di "R-squared: " e(r2)
di "N: " e(N)
********************************************************************************
////////////////////////////////////////////////////////////////////////////////
/// price dispersion

clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_315.dta"

foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(ticketcarrier, "`x'")>0
}

gen dt = yq(year, quarter)
gen MktFare_sd=sqrt(MktFare_v)
gen mktdistance100 = mktdistance/100
gen mktdistance1002=mktdistance100^2
/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)

reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg1_v

gen lnq1= ln(q1)
gen lnq05= ln(q05)
gen lnq10= ln(q10)
gen lnq15= ln(q15)
gen lnq20= ln(q20)
gen lnq25= ln(q25)
gen lnq30= ln(q30)
gen lnq35= ln(q35)
gen lnq40= ln(q40)
gen lnq45= ln(q45)
gen lnq50= ln(q50)
gen lnq55= ln(q55)
gen lnq60= ln(q60)
gen lnq65= ln(q65)
gen lnq70= ln(q70)
gen lnq75= ln(q75)
gen lnq80= ln(q80)
gen lnq85= ln(q85)
gen lnq90= ln(q90)
gen lnq99= ln(q99)

reg  lnmktfare roundtrip nonstop mktcoupons online_new  mktdistance100 mktdistance1002 nea_market ///
 nea_market_codeshared    ///
 i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 
est sto reg1

reg  lnmktfare roundtrip nonstop mktcoupons online_new mktdistance100 mktdistance1002 nea_market ///
 nea_market_codeshared nea_market_codeshared_b6 nea_market_codeshared_aa    ///
 i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 
est sto reg1_b6_aa

///
reg  lnq05 roundtrip nonstop mktcoupons online_new mktdistance100 mktdistance1002 nea_market ///
 nea_market_codeshared  nea_market_codeshared_b6 nea_market_codeshared_aa ///
 i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 





////////////////////////////////////////////////////////////////////////////////
///local dependent_vars lnq1 lnq05 lnq10 lnq15 lnq20 lnq25 lnq30 lnq35 lnq45 ///
///lnq50 lnq55 lnq60 lnq65 lnq70 lnq75 lnq80 lnq85 lnq90 lnq99


/// the average impact in a market
local dependent_vars q1 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99
foreach var of local dependent_vars {
    * Run the regression model
    quietly reg ln`var' roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared ///
i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
    * Store the estimation results
    est store `var'
}


/// plot
coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared) vertical bycoefs ytitle("Impact of NEA Codeshare") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))

graph export "E:\Research\Codeshare JetBlue AA\Stata File\Price_Dispersion.png", replace
/// no grey/green background looks prettier

////////////////////////////////////////////////////////////////////////////////
/// look at B6 AA and otherairline seperately


gen nea_market_codeshared_b6 = nea_market_codeshared* B6
gen nea_market_codeshared_aa = nea_market_codeshared* AA 

local dependent_vars q1 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99
foreach var of local dependent_vars {
    * Run the regression model
    quietly reg ln`var' roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6 ///
i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
    * Store the estimation results
    est store `var'
}


/// the average impact in a market except b6 and aa
coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared_aa) vertical bycoefs ytitle("Impact of NEA Codeshare on AA Airfare Dispersion") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "E:\Research\Codeshare JetBlue AA\Stata File\Price_Dispersion_AA.png", replace

coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared_b6) vertical bycoefs ytitle("Impact of NEA Codeshare on B6 Airfare Dispersion") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "E:\Research\Codeshare JetBlue AA\Stata File\Price_Dispersion_B6.png", replace

********************************************************************************
////////////////////////////////////////////////////////////////////////////////
/// price dispersion excluding small markets with market fixed effects 
gen lnmktfare = ln(mktfare)


/// delete samll markets 

egen total_quantity = total( passengers), by(market year quarter)

drop if total_quantity<2000
/// N= 752010, may need robostness check here
egen newidd = group(market) 
///1957 markets left
sum newidd

set matsize 2200


reg MktFare_sd roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 
est sto reg1_v

reg lnmktfare roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market nea_market_codeshared i.dt WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers] 


/// the average impact in a market
local dependent_vars q1 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99
foreach var of local dependent_vars {
    * Run the regression model
    quietly reg ln`var' roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
    * Store the estimation results
    est store `var'
}

coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared) vertical bycoefs ytitle("Impact of NEA Codeshare") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "E:\Research\Codeshare JetBlue AA\Stata File\Price_Dispersion_MFE.png", replace

////////////////////////////////////////////////////////////////////////////////
/// look at B6 AA and otherairline seperately


local dependent_vars q1 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99
foreach var of local dependent_vars {
    * Run the regression model
    quietly reg ln`var' roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
 nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6 ///
i.dt i.newidd  WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers]
    * Store the estimation results
    est store `var'
}


/// the average impact in a market except b6 and aa
coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared_aa) vertical bycoefs ytitle("Impact of NEA Codeshare on AA Airfare Dispersion") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "E:\Research\Codeshare JetBlue AA\Stata File\Price_Dispersion_MFE_AA.png", replace

coefplot q1 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared_b6) vertical bycoefs ytitle("Impact of NEA Codeshare on B6 Airfare Dispersion") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "E:\Research\Codeshare JetBlue AA\Stata File\Price_Dispersion_MFE_B6.png", replace



/// std with market fixd effects 
reg MktFare_sd roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6  ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg3_v_mfe

reg lnq1 roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6  ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg3_q1_mfe


reg lnq25 roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6  ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg3_q25_mfe

reg lnq50 roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6  ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg3_q50_mfe

reg lnq75 roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6  ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg3_q75_mfe

reg lnq99 roundtrip nonstop mktcoupons mktdistance100 mktdistance1002 ///
nea_market_codeshared nea_market_codeshared_aa nea_market_codeshared_b6  ///
i.dt i.newidd WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM[aweight = passengers], cluster(market) 
est sto reg3_q99_mfe

estout reg3_v_mfe reg3_q1_mfe reg3_q25_mfe reg3_q50_mfe reg3_q75_mfe reg3_q99_mfe  using ///
 result323_marketfixed_selected.xls, cells("b" se)  replace
 
est restore reg3_v_mfe
//ereturn list
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg3_q1_mfe
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg3_q25_mfe
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg3_q50_mfe
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg3_q75_mfe
di "R-squared: " e(r2)
di "N: " e(N)

est restore reg3_q99_mfe
di "R-squared: " e(r2)
di "N: " e(N)
