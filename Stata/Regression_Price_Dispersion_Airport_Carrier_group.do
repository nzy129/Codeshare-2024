// this file computes the dispersion with 
///////////////////////////////////////////////////////////////////////////////
/// import the data, cleaned in Python

clear all
import delimited "F:\Codeshare JetBlue AA\pythonProject3\Cleaned_2019_2023_without_delete_small_market_dispersion_47_airports.csv"



foreach x in "WN" "AA" "DL" "UA" "NK" "AS" "B6" "F9" "G4" "HA" "SY" "XP" "MX" "MM" {
gen `x' = strpos(tkcarriergroup, "`x'")>0
}


/// delete the first row
gen row_i = _n
drop if row_i==1
drop row_i
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
drop v34 v35
gen dt = yq(year, quarter)

destring mktfare, replace
destring MktFare_v, replace
destring q1 q05 q10 q15 q20 q25 q30 q35 q40 q45 q50 q55 q60 ///
q65 q70 q75 q80 q85 q90 q99, replace
destring mktdistance passengers nonstop, replace

gen MktFare_sd=sqrt(MktFare_v)
gen mktdistance100 = mktdistance/100
gen mktdistance1002 = mktdistance100^2
gen incon = mktdistance/nonstopmiles





egen nea_market2 = total(nea_market_codeshared), by(market)
gen nea_market=nea_market2>1
drop nea_market2


save "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_48.dta" 
///, replace
clear all
use "F:\Codeshare JetBlue AA\pythonProject3\Codeshare_stata_48.dta"

sum passengers, de


hist passengers if passengers<20
/// delete covid period 
drop if year==2020 |year ==2021 |(year==2022 & quarter ==1)
/// delete samll markets 
drop total_quantity
egen total_quantity = total( passengers), by(market year quarter)

drop if total_quantity<10000

// delete the missing information
drop if strpos(tkcarriergroup, "--")>0


// plan to delete the route with fewer than 10 passengers
drop if passengers<10
********************************************************************************
///////////////////////////////////////////////////////////////////////////////
/// regression of market fare

gen lnmktfare = ln(mktfare)
egen newidd = group(airportgroup)
/// 2757 routes and 32760 obs
sum newidd nea_market_codeshared

gen interline =  tkcarriergroup == opcarriergroup & online_new ==0

split opcarriergroup, parse(":") gen(opcarriers)

gen num_op_carriers = 3-missing(opcarriers1)-missing(opcarriers2)-missing(opcarriers3)
split tkcarriergroup, parse(":") gen(tkcarriers)
gen num_tk_carriers = 3-missing(tkcarriers1)-missing(tkcarriers2)-missing(tkcarriers3)

gen t_codeshare = 0
replace t_codeshare = 1 if num_op_carriers==2 & opcarriers1 ~= opcarriers2 & tkcarriers1 == tkcarriers2
replace t_codeshare = 1 if num_op_carriers==3 & opcarriers1 ~= opcarriers2 & tkcarriers1 == tkcarriers2
replace t_codeshare = 1 if num_op_carriers==3 & opcarriers2 ~= opcarriers3 & tkcarriers2 == tkcarriers3
replace t_codeshare = 1 if num_op_carriers==3 & opcarriers1 ~= opcarriers3 & tkcarriers1 == tkcarriers3

gen v_codeshare = 0
replace v_codeshare = 1 if num_op_carriers==1 & opcarriers1 ~= tkcarriers1 
replace v_codeshare = 1 if num_op_carriers==2 & opcarriers1 == opcarriers2 & tkcarriers1 == opcarriers2 & tkcarriers1~= opcarriers1
replace v_codeshare = 1 if num_op_carriers==3 & opcarriers1 == opcarriers2 & opcarriers1 == opcarriers3 ///
 & tkcarriers1~= opcarriers1 & opcarriers1== opcarriers2 & opcarriers2== opcarriers3

gen pure_online = online_new==1 & v_codeshare==0
gen b6aa_c  = strpos(opcarriergroup, "AA")& strpos(opcarriergroup, "B6") & online_new ==0 & interline ==0 &v_codeshare==0


set matsize 4000

reg mktfare roundtrip nonstop t_codeshare v_codeshare interline online_new ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.newidd [aweight = passengers], cluster(market)

est sto reg_mf_airportsgroup

reg MktFare_sd roundtrip nonstop t_codeshare v_codeshare interline online_new ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared i.dt i.newidd [aweight = passengers], cluster(market)

est sto reg_mf_airportsgroup_sd


 
gen dummy_bos = (strpos(airportgroup, "BOS") > 0)

gen dummy_jfk = (strpos(airportgroup, "JFK") > 0)

gen dummy_ewr = (strpos(airportgroup, "EWR") > 0)

gen dummy_lga = (strpos(airportgroup, "LGA") > 0)

reg mktfare roundtrip nonstop t_codeshare v_codeshare interline online_new ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.dummy_bos 1.nea_market_codeshared#1.dummy_jfk ///
1.nea_market_codeshared#1.dummy_ewr 1.nea_market_codeshared#1.dummy_lga i.dt i.newidd [aweight = passengers], cluster(market)

est store reg_mf_airportsgroupss
 

reg MktFare_sd roundtrip nonstop t_codeshare v_codeshare interline online_new ///
 1.b6aa_c#1.AA 1.b6aa_c#1.B6 WN AA DL UA NK AS B6 F9 G4 HA SY XP MX MM  ///
 nea_market_codeshared 1.nea_market_codeshared#1.dummy_bos 1.nea_market_codeshared#1.dummy_jfk ///
1.nea_market_codeshared#1.dummy_ewr 1.nea_market_codeshared#1.dummy_lga i.dt i.newidd [aweight = passengers], cluster(market)

 
est store reg_mf_airportsgroupsssd
 
 
estout reg_mf_airportsgroup reg_mf_airportsgroup_sd reg_mf_airportsgroupss ///
reg_mf_airportsgroupsssd using result419mf.xls, cells("b" se)  replace
 
 
********************************************************************************

 
 
 
 
 
 
 
 
 
 
 
 