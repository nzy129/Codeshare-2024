/*
 Codeshare Alliance between JetBlue and American Airlines written by Zheyu Ni 
at The Ohio State University, 3/20/2024
This file estimates the impact of NEA on price dispersion.
*/
/// import the data 
clear all
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\cleaned_2019_2023_stata_35.csv"

save "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta", replace

clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta"


foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(ticketcarrier, "`x'")>0
}


/// descriptive analysis
set more off
gen incon = mktdistance/nonstopmiles

/// generate NONSTOP
/// gen n_airpots = length(airportgroup) - length(subinstr(airportgroup, ":", "", .)) + 1
/// gen nonstop = n_airpots ==2

sum avefare nonstop roundtrip incon online_new interline t_codeshare v_codeshare mktcoupons mktdistance nonstopmiles ///
b6aa AA B6 DL UA WN [aweight=passengers]

sum incon if nonstop==0
///codebook market
///codebook market if total_quantity>100
///markt level statistics

///collapse (sum) passengers , by(year quarter market nea_market) 

///sum nea_market 

bysort year quarter market: gen noproduct = _N
bysort market: egen total_pa = total(passengers)

collapse (sum) passengers , by(year quarter market nea_market noproduct) 

sum nea_market noproduct
/// BOS, LGA, EWR, 
/// drop if strpos(market, "BOS")
/// generate the indicator if the flight is codeshared by the B6 and AA
// DELETE the missing data
/// drop if strpos(opcarriergroup, "B6")

///tab ticketcarrier, gen(tk)

********************************************************************************
// graph passengers data
clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta"

// collapse by market
collapse (sum) passengers , by(year quarter nea_market) 

gen dt = yq(year, quarter)
format dt %tq

graph twoway (line passengers dt if nea_market == 1)(line passengers dt if nea_market == 0), ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
xline(244, lwidth(52) lc(gs12)) xline(240,lp(dash)) xline(248,lp(dash)) ///
 legend(label(1 NEA markets) label(2 Non-NEA Market) ) /// 
 title("No. Passengers from 2019Q1 to 2023Q3") yti("Passengers") ///
 graphregion(color(white)) plotregion(color(white))

 
 
********************************************************************************
// graph airfare
clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta"
collapse (mean) avefare [aweight = passengers], by(year quarter) 

gen dt = yq(year, quarter)
format dt %tq
graph twoway line avefare dt
graph export "collapsed_data_plot.png", replace

save collapsed_data, replace

// collapse by market

clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta"
collapse (mean) avefare [aweight = passengers], by(year quarter nea_market ) 
gen dt = yq(year, quarter)
format dt %tq


graph twoway (line avefare dt if nea_market == 1)(line avefare dt if nea_market == 0), ///
tline(244 254,lp(dash) lc(black)) tla(244 "NEA Starts" 254 "Ends", add angle(45)) ///
xline(244, lwidth(52) lc(gs12)) xline(240,lp(dash)) xline(248,lp(dash)) ///
 legend(label(1 NEA markets) label(2 Non-NEA Market) ) /// 
 title("Weighted Average Price from 2019Q1 to 2023Q3") yti("Weighted Price") ///
 graphregion(color(white)) plotregion(color(white))

********************************************************************************
/// regression 

clear all
import delimited "E:\Research\Codeshare JetBlue AA\pythonProject3\cleaned_2019_2023_stata35.csv"
gen lnfare = ln(avefare)


save "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta", replace

clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_35.dta"

foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(ticketcarrier, "`x'")>0
}

gen dt = yq(year, quarter)

gen mktdistance100 = mktdistance/100
gen mktdistance1002 = mktdistance100^2
gen incon = mktdistance/nonstopmiles
gen b6aa_c = b6aa*(1-interline)


reg avefare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
 mktdistance100 mktdistance1002 b6aa_c WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt, cluster(market)
est sto reg2


reg avefare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 b6aa_c WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt [aweight = passengers], cluster(market)

est sto reg1_weight 

reg avefare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt[aweight = passengers], cluster(market)
est sto reg2_weight

reg lnfare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt[aweight = passengers], cluster(market)

est sto reg3_weight


/// check the whole markets price for AA and B6 products
reg lnfare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 b6aa_c WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM nea_market nea_market_codeshared ///
1.nea_market_codeshared#1.AA 1.nea_market_codeshared#1.B6 ///
i.dt [aweight = passengers]
est sto reg4_weight

estout reg2 reg1_weight  reg2_weight reg3_weight reg4_weight using result222_excludecovid.xls, cells("b" se)  replace


// check R_square and number of the observations
foreach x  in "reg2" "reg1_weight"  "reg2_weight" "reg3_weight" "reg4_weight"  {

est restore `x'
di "R-squared: " e(r2)
di "N: " e(N)
}

********************************************************************************
/// delete samll markets  
*drop if total_quantity<2000

egen newidd = group(market)
sum newidd
set matsize 2200


reg lnfare roundtrip interline online_new  1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt i.newidd[aweight = passengers]

est sto reg_market_fixed_ln

reg avefare roundtrip interline online_new  1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt i.newidd[aweight = passengers]

est sto reg_market_fixed


estout reg_market_fixed_ln reg_market_fixed using result222_marketfixed.xls, cells("b" se)  replace
********************************************************************************
/// delete covid period for regression
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)


reg avefare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 b6aa_c WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt [aweight = passengers], cluster(market)

est sto reg1_weight_noc

reg avefare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared  i.dt[aweight = passengers], cluster(market)
est sto reg2_weight_noc

reg lnfare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY ///
XP MX MM nea_market nea_market_codeshared i.dt[aweight = passengers], cluster(market)

est sto reg3_weight_noc


/// check the whole markets price for AA and B6 products
reg lnfare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
mktdistance100 mktdistance1002 b6aa_c WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM nea_market nea_market_codeshared ///
1.nea_market_codeshared#1.AA 1.nea_market_codeshared#1.B6 ///
i.dt [aweight = passengers]
est sto reg4_weight_noc



estout reg1_weight_noc reg2_weight_noc reg3_weight_noc reg4_weight_noc using result222_excludecovid.xls, cells("b" se)  replace


// check R_square and number of the observations
foreach x  in "reg1_weight_noc"  "reg2_weight_noc" "reg3_weight_noc" "reg4_weight_noc"  {

est restore `x'
di "R-squared: " e(r2)
di "N: " e(N)
}


********************************************************************************
/// market fixed effects | without covid
drop if total_quantity <2000
egen newidd = group(market)
sum newidd
///drop covid year only, there are 101322 markets. 
///drop small than 2000, there are 1959 markets left


reg avefare roundtrip nonstop incon t_codeshare v_codeshare interline online_new ///
 1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.newidd [aweight = passengers], cluster(market)

est sto reg_market_fixed_nocovid  
  
/// market fixed effects | without covid | log fare
reg lnfare roundtrip nonstop incon t_codeshare v_codeshare interline online_new  ///
1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
 nea_market_codeshared i.dt i.newidd [aweight = passengers], cluster(market)

est sto reg_market_fixed_nocovid_ln

reg lnfare roundtrip nonstop incon t_codeshare v_codeshare interline online_new  ///
1.b6aa#1.AA 1.b6aa#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM ///
nea_market_codeshared 1.nea_market_codeshared#1.AA 1.nea_market_codeshared#1.B6 ///
i.dt i.newidd [aweight = passengers], cluster(market)

est sto reg_mf_nocovid_ln_b6aa


estout reg_market_fixed_nocovid reg_market_fixed_nocovid_ln ///
reg_mf_nocovid_ln_b6aa using result222_marketfixed_nocovid.xls, cells("b" se)  replace

foreach x  in "reg_market_fixed_nocovid"  "reg_market_fixed_nocovid_ln" "reg_mf_nocovid_ln_b6aa" {

est restore `x'
di "R-squared: " e(r2)
di "N: " e(N)
}


