********************************************************************************
**## DID: marketfare with Market Fixed Effects
*******************************************************************************

use "cleaned717_dropsmallmarket.dta", clear 

* log price
gen lnmktfare = ln(mktfare)

*origin-dest level id
egen mktgroupid = group(market) /// 244 mkts

* check the comparasion between nea mad non-nea market before 2021
tabstat passengers mktfare if year<2021, by(nea_market) statistics(mean median sd min max)

set matsize 400

reg mktfare roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare  pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.mktgroupid [aweight = passengers], cluster(market)

est sto reg_mf_airportsgroup

reg lnmktfare roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare  pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.mktgroupid [aweight = total_quantity], cluster(market)

est sto reg_mf_airportsgroupln

reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002  /// 
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.mktgroupid [aweight = passengers], cluster(market)

est sto reg_mf_airportsgroup_sd

* reg for the market with JetBlue is a new entrant
reg mktfare roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.mktgroupid [aweight = passengers] if ///
 JetBlue_new_market_served==1, cluster(market) 
est sto reg_mf_newmarket

* reg for the market where JetBlue is NOT a new entrant
reg mktfare roundtrip nonstop mktdistance100 mktdistance1002  /// 
t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.mktgroupid [aweight = passengers] if ///
 JetBlue_new_market_served==0, cluster(market) 
est sto reg_mf_not_newmarket

* interation between Codeshare and JetBlue_new_market_served
reg mktfare roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.JetBlue_new_market_served ///
 i.dt i.mktgroupid [aweight = passengers], cluster(market) 

 est sto reg_mf_JetBlue_newmarket
 
 * standard deviation
reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.JetBlue_new_market_served ///
 i.dt i.mktgroupid [aweight = passengers], cluster(market) 

est sto reg_mf_JetBlue_newmarketsd

estout reg_mf_newmarket reg_mf_not_newmarket reg_mf_JetBlue_newmarket reg_mf_JetBlue_newmarketsd ///
using result7312024mf_jbn.xls, cells("b(star fmt(4))" se)stats(r2 N)  replace

* Airport level 

gen dummy_bos = (strpos(airportgroup, "BOS") > 0)
gen dummy_jfk = (strpos(airportgroup, "JFK") > 0)
gen dummy_ewr = (strpos(airportgroup, "EWR") > 0)
gen dummy_lga = (strpos(airportgroup, "LGA") > 0)

reg mktfare roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.dummy_bos 1.nea_market_codeshared#1.dummy_jfk ///
1.nea_market_codeshared#1.dummy_ewr 1.nea_market_codeshared#1.dummy_lga i.dt i.mktgroupid [aweight = passengers], cluster(market)

est store reg_mf_airportsgroupss

reg lnmktfare roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.dummy_bos 1.nea_market_codeshared#1.dummy_jfk ///
1.nea_market_codeshared#1.dummy_ewr 1.nea_market_codeshared#1.dummy_lga i.dt i.mktgroupid [aweight = passengers], cluster(market)

est store reg_mf_airportsgroupssln

reg MktFare_sd roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.dummy_bos 1.nea_market_codeshared#1.dummy_jfk ///
1.nea_market_codeshared#1.dummy_ewr 1.nea_market_codeshared#1.dummy_lga i.dt i.mktgroupid [aweight = passengers], cluster(market)

est store reg_mf_airportsgroupsssd
  
estout reg_mf_airportsgroup reg_mf_airportsgroupln reg_mf_airportsgroup_sd reg_mf_airportsgroupss ///
reg_mf_airportsgroupssln reg_mf_airportsgroupsssd using result7312024mf.xls, cells("b(star fmt(4))" se)stats(r2 N) replace

*******************************************************************************
**# quantile
*******************************************************************************

* save graph in graph folder
cd "F:\Codeshare JetBlue AA\STATA_New_Data_7_2024\graph"


* generate log price
local quantile_list q01 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99

foreach var of local quantile_list {
 cap gen ln`var'= ln(`var')
}

* regression
foreach var of local quantile_list {
    * Run the regression model
    quietly reg ln`var' roundtrip nonstop mktdistance100 mktdistance1002  ///
	 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.dummy_bos 1.nea_market_codeshared#1.dummy_jfk ///
1.nea_market_codeshared#1.dummy_ewr 1.nea_market_codeshared#1.dummy_lga i.dt i.mktgroupid [aweight = passengers], cluster(market)

    * Store the estimation results
    est store `var'
}

* plot 
* BOS
coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(1.nea_market_codeshared#1.dummy_bos) vertical bycoefs ytitle("Impact of NEA Codeshare in BOS Airport") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))

graph export "Price_Dispersion_MFE_BOS_carriergroup.png", replace

* JFK
coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(1.nea_market_codeshared#1.dummy_jfk) vertical bycoefs ytitle("Impact of NEA Codeshare in JFK Airport") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "Price_Dispersion_MFE_JFK_carriergroup.png", replace

* LGA
coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(1.nea_market_codeshared#1.dummy_lga) vertical bycoefs ytitle("Impact of NEA Codeshare in LGA Airport") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "Price_Dispersion_MFE_LGA_carriergroup.png", replace

* EWR
coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(1.nea_market_codeshared#1.dummy_ewr) vertical bycoefs ytitle("Impact of NEA Codeshare ") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "Price_Dispersion_MFE_EWR_carriergroup.png", replace

*Other codeshared markets
coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(nea_market_codeshared) vertical bycoefs ytitle("Impact of NEA Codeshare ") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "Price_Dispersion_MFE_Other_carriergroup.png", replace

* JetBlue Entry

local dependent_vars q01 q05 q10 q15 q20 q25 q30 q35 q45 ///
q50 q55 q60 q65 q70 q75 q80 q85 q90 q99
foreach var of local dependent_vars {
    * Run the regression model
    quietly reg ln`var' roundtrip nonstop mktdistance100 mktdistance1002  ///
 t_codeshare v_codeshare pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 1.nea_market_codeshared JetBlue_new_market_served ///
 1.nea_market_codeshared#1.JetBlue_new_market_served ///
 i.dt i.mktgroupid [aweight = passengers], cluster(market)

    * Store the estimation results
    est store `var'
}


* plot 
coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(1.nea_market_codeshared#1.JetBlue_new_market_served) vertical bycoefs ytitle("Impact of NEA Codeshare in Newly Entered Market") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "Price_Dispersion_MFE_New_Market.png", replace



coefplot q01 || q05 || q10 || q15 || q20 || q25 || q30 || q35 || q45 || ///
 q50 || q55 || q60 || q65 || q70 || q75 || q80 || q85 || q90 || q99, ///
 keep(1.nea_market_codeshared) vertical bycoefs ytitle("Impact of NEA Codeshare in All Markets") ///
xtitle("Selected Percentiles") ///
recast(connected)  ciopts(recast(rarea) color(gs14) lpattern(dash)) ///
graphregion(color(white)) plotregion(color(white))
graph export "Price_Dispersion_MFE_NonNew_Market.png", replace
********************************************************************************
**## DID: Direct Flight 
********************************************************************************

drop if nonstop ==1

reg mktfare roundtrip  ///
 t_codeshare v_codeshare  pure_online ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.mktgroupid [aweight = passengers], cluster(market)



********************************************************************************
**# DID: The effects on the number of passengers by Carriers
********************************************************************************


*** End of File
