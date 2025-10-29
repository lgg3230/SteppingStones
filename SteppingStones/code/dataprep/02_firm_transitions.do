********************************************************************************
* PROJECT: Stepping Stones
* AUTHOR: LUIS GOMES
* PROGRAM: GENERATE WORKER AND FIRM LEVEL MEAUSURES
* INPUT: WORKER LEVEL PANEL 
* OUTPUT: WORKER LEVEL PANEL 
********************************************************************************


use "$analysis/worker_estab_all_years.dta", clear

keep if inrange(year, 2010, 2014)

xtile age_bin = idade,  nquantiles(10)
label var age_bin "employee age deciles"

xtile ten_bin  = tempempr, nquantiles (10)
label var ten_bin "employee tenure deciles, monthly"

*
// Industry categories
*

gen clascnae20_clean = ustrregexra(clascnae20,  "[^0-9]", "")

gen big_industry = substr(clascnae20_clean, 1, 2)

destring big_industry, replace force

// 2. Broad Industry Categories
gen broad_industry = .
label define broad_ind_lbl ///
    1 "Farming/fishing" ///
    2 "Extractive ind." ///
    3 "Manufacturing" ///
    4 "Utilities" ///
    5 "Construction" ///
    6 "Trade/commerce" ///
    7 "Transportation" ///
    8 "Hospitality" ///
    9 "Communication" ///
    10 "Banking/finance" ///
    11 "Real estate" ///
    12 "Professional act." ///
    13 "Administrative act." ///
    14 "Public admin." ///
    15 "Education" ///
    16 "Health" ///
    17 "Culture/sports" ///
    18 "Other"
label values broad_industry broad_ind_lbl

// Industry category assignments
replace broad_industry = 1 if inlist(big_industry, 1, 2, 3)
replace broad_industry = 2 if inrange(big_industry, 5, 9)
replace broad_industry = 3 if inrange(big_industry, 10, 33)
replace broad_industry = 4 if inrange(big_industry, 35, 39)
replace broad_industry = 5 if inrange(big_industry, 41, 43)
replace broad_industry = 6 if inrange(big_industry, 45, 47)
replace broad_industry = 7 if inrange(big_industry, 49, 53)
replace broad_industry = 8 if inrange(big_industry, 55, 56)
replace broad_industry = 9 if inrange(big_industry, 58, 63)
replace broad_industry = 10 if inrange(big_industry, 64, 66)
replace broad_industry = 11 if big_industry == 68
replace broad_industry = 12 if (inrange(big_industry, 69, 75) | inrange(big_industry, 77, 79))
replace broad_industry = 13 if inrange(big_industry, 80, 82)
replace broad_industry = 14 if big_industry == 84
replace broad_industry = 15 if big_industry == 85
replace broad_industry = 16 if inrange(big_industry, 86, 88)
replace broad_industry = 17 if inrange(big_industry, 90, 91)
replace broad_industry = 18 if inrange(big_industry, 92, 99)


*
// Measure of firm productivity is average firm wage over the years
*

egen lr_firm_wage_avg = mean(lr_remmedr), by(identificad)
label var lr_firm_wage_avg "Mean average firm wage over the period"


*
// Generate forward variables
*

destring PIS, generate(pis_d)
label var pis_d "employee id, destring"

destring identificad, generate(cnpj)
label var cnpj "employer identifier, destring"

xtset pis_d year

fillin pis_d year

// employees that remain at the same firm across years


cap drop cnpj_ny
cap drop samefirm_1
gen cnpj_ny = F1.cnpj
gen samefirm_1 = cnpj_ny==cnpj
label var samefirm_1 "employees that remain in the same firm as last year"


forvalues i =1/4{
	cap drop cnpj_`i'y
	gen cnpj_`i'y = F`i'.cnpj
	
}


cap drop lr_remmedr_ny
gen lr_remmedr_ny = F1.lr_remmedr
label var lr_remmedr_ny "avg wage during next year" // this is not right, needs to be wage at next year's employment 

cap drop quit
gen quit = inlist(causadesli, 20,21)



cap drop layoff
gen layoff  = inlist(causadesli, 10, 11)


cap drop quit_ny
 gen quit_ny = F.quit
 label var quit_ny "employer quit next year"


*
// employees that voluntarily change firms across years
*


gen lr_firm_wage_avg_ny = F1.lr_firm_wage_avg

gen quit_next_firm_q = quit*lr_firm_wage_avg_ny




