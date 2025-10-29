********************************************************************************
* PROJECT: Stepping Stones
* AUTHOR: LUIS GOMES
* PROGRAM: SELECT PEOPLE THAT SWITCHED JOBS VOLUNTARILY AND INVOLUNTARILY
* INPUT: WORKER LEVEL PANEL 
* OUTPUT: WORKER LEVEL PANEL 
********************************************************************************



local years " 2008 2009 2010 2011 2012 2013 2014 2015 2016"
local ipca  "  0.643834976197206 0.671594887351247 0.711277338716318 0.757534213038901 0.80176356558955 0.849153270408197 0.903562518222102 1 1.06287988213221 1.09420743038879"


forvalues i=2010/2014{
	
 	local i=2009
	use "$rais_raw_dir/RAIS_`i'.dta",clear
	
	
local years " 2008 2009 2010 2011 2012 2013 2014 2015 2016"
local ipca  "  0.643834976197206 0.671594887351247 0.711277338716318 0.757534213038901 0.80176356558955 0.849153270408197 0.903562518222102 1 1.06287988213221 1.09420743038879"
	
	
	
	
	* Generate year variables
	
	gen year = `i' // generates year variable for whole dataset, used later to mactch with cba data
	gen identificad_8 = substr(identificad,1,8) // firm identifier, only 1st 8 digits of cnpj
	
	* Step 1: Check what age-related variables exist and create missing ones
cap confirm var idade
if _rc {
    gen idade = .
    di "idade variable created as missing"
}

cap confirm var dtnascimento  
if _rc {
    gen dtnascimento = ""
    di "dtnascimento variable created as missing"
}

* Step 2: Ensure dtnascimento is string format for consistent processing
capture confirm string variable dtnascimento
if _rc {
    tostring dtnascimento, replace force
}

* Step 3: Create a unified age variable that works across all years
gen idade_unified = .

* Case 1: If we have idade (age) but no dtnascimento, use idade directly
count if !missing(idade) & (missing(dtnascimento) | dtnascimento == "")
if r(N) > 0 {
    replace idade_unified = idade if !missing(idade) & (missing(dtnascimento) | dtnascimento == "")
    di "Using idade for " r(N) " observations"
}

* Case 2: If we have dtnascimento but no idade, calculate age from birthday
count if (missing(idade) | idade == .) & !missing(dtnascimento) & dtnascimento != ""
if r(N) > 0 {
    * Convert birthday to Stata date format
    gen dob_date = date(dtnascimento, "DMY")
    format dob_date %td
    
    * Calculate age as of December 31st of current year
    gen ref_date = mdy(12, 31, `i')
    gen calculated_age = (ref_date - dob_date) / 365.25
    replace calculated_age = floor(calculated_age)
    
    * Use calculated age where idade is missing
    replace idade_unified = calculated_age if (missing(idade) | idade == .) & !missing(calculated_age)
    
    di "Calculated age from dtnascimento for " r(N) " observations"
    
    * Clean up temporary variables
    drop dob_date ref_date calculated_age
}

* Case 3: If we have both, prefer dtnascimento (more precise) but use idade as fallback
count if !missing(idade) & !missing(dtnascimento) & dtnascimento != ""
if r(N) > 0 {
    * First try to calculate from dtnascimento
    gen dob_date = date(dtnascimento, "DMY")
    format dob_date %td
    gen ref_date = mdy(12, 31, `i')
    gen calculated_age = (ref_date - dob_date) / 365.25
    replace calculated_age = floor(calculated_age)
    
    * Use calculated age where it's valid, otherwise use idade
    replace idade_unified = calculated_age if !missing(calculated_age) & calculated_age >= 0 & calculated_age <= 100
    replace idade_unified = idade if missing(idade_unified) & !missing(idade) & idade >= 0 & idade <= 100
    
    di "Used dtnascimento for " r(N) " observations with both variables available"
    
    * Clean up temporary variables
    drop dob_date ref_date calculated_age
}

* Step 4: Create standardized age and birthday variables for consistency
* Standardize idade to use the unified version
replace idade = idade_unified if !missing(idade_unified)

* Create a standardized dtnascimento variable
gen dtnascimento_std = dtnascimento
replace dtnascimento_std = "" if missing(dtnascimento_std)

	
	// homogenizing variables across years.
	* Core variables available -2016
    keep year PIS CPF numectps nome identificad identificad_8 municipio ///
     tpvinculo empem3112 tipoadm dtadmissao causadesli mesdesli ///
     ocup2002 grinstrucao genero dtnascimento idade nacionalidad ///
     portdefic tpdefic raca_cor remdezembro remmedia remdezr remmedr ///
     tempempr tiposal salcontr ultrem horascontr clascnae20 sbclas20 ///
     tamestab natjuridica tipoestbl indceivinc ceivinc indalvara ///
     indpat indsimples causafast1 causafast2 causafast3 ///
     diainiaf1 diainiaf2 diainiaf3 diafimaf1 diafimaf2 diafimaf3 ///
     mesiniaf1 mesiniaf2 mesiniaf3 mesfimaf1 mesfimaf2 mesfimaf3

	order year PIS CPF numectps nome identificad identificad_8 municipio ///
     tpvinculo empem3112 tipoadm dtadmissao causadesli mesdesli ///
      ocup2002 grinstrucao genero dtnascimento idade nacionalidad /// 
      portdefic tpdefic raca_cor remdezembro remmedia remdezr remmedr /// 
      tempempr tiposal salcontr ultrem horascontr clascnae20 sbclas20 /// 
      tamestab natjuridica tipoestbl indceivinc ceivinc indalvara /// 
      indpat indsimples  causafast1 causafast2 causafast3 /// 
      diainiaf1 diainiaf2 diainiaf3 diafimaf1 diafimaf2 diafimaf3 /// 
      mesiniaf1 mesiniaf2 mesiniaf3 mesfimaf1 mesfimaf2 mesfimaf3
	
	
	di "keep successfull"
	
	// converting identifiers to double in order to apply Lagos(2021) selection rules
	destring PIS, gen(PIS_d)
	destring identificad, gen(identificad_d)
	
	// remove invalid identifiers or remuneration (drop if x==1)
	// from Lagos (2021), PIS_d removes very few obs, identificad_d removes no obs, remdezr<=0 removes part of people not employed through dec.
// 	gen x= (PIS_d<1000) | (identificad_d<=0) | (remdezr<=0)
// 	tab x // nobody, in 2009 at least 
//  	drop if x==1
// 	drop x 
 
    * Convert the date of admission from string to a Stata date and format it
    gen dtadmissao_stata = date(dtadmissao, "DMY")
    format dtadmissao_stata %td 
//


//     * Create a dummy that equals 1 if the hiring date is on or before December 1 of year `i'
     gen hired_ndec = (dtadmissao_stata <= mdy(11,30,`i'))
//
//     * Create a dummy that equals 1 if the employee is active in December of year `i'
//     * (active means the hiring date is on or before December 1 of `i' and mesdesli equals 0)
//     gen emp_in_dec = (dtadmissao_stata <= mdy(11,30,`i') & mesdesli == 0) // 
    
    // generate dummy of employment in december according to Lagos(2021) -- let's use this one instead of ours
    
    * *********************
    * Wage outcomes
    * *********************
    
// Adjust wage variables: 

** Log-contracted-wages 

// Adjust 2016 contracted wages according to Lagos (2024)'s footnote 76: multiply by 100 any contracted wage below minimum wage.

if `i'==2016{
	replace salcontr = 100*salcontr if salcontr<880
}
 


// salcontr is non missing only for 10% of the spells in some years. 
// adjusting wage measure for each contract type. This does not changes the dist too much



    gen salcontr_m = .
    replace salcontr_m = salcontr if inlist(tiposal, 1, 6, 7) // keep the same if salaray is monthly, other or per task (dont know how to deal with per task)
    replace salcontr_m = 2 * salcontr if tiposal == 2 // multiply by two if it is biweekly
    replace salcontr_m = 4.348 * salcontr if tiposal == 3 // multiply by avg number of weeks if weekly
    replace salcontr_m = 30.436875 * salcontr if tiposal == 4 // multiply by avg number of days if daily
    replace salcontr_m = 4.348 * horascontr * salcontr if tiposal == 5 // multiply by monthly hours if hourly
    label var salcontr_m "Salario contratual, ajustado para valor mensal de acordo com o tipo de salario"
    
    gen salcontr_h = salcontr_m/(horascontr*4.348) // contractual salary divided by the amount of contracted hours in the month
    label var salcontr_h "Salario contratual dividido pelo total de horas trabalhadas no mes"

	
** Log average wages
    
    ** using wage type, convert average earnings to monthly measure
        
    // I will not do any adjustment to average earnings because this makes the dist look very weird. I did not understand Lagos' (2024) hourly adjustment.
    // Lagos (2024) "hourly adjustment": When this outcome is reported as "hourly," I divide the average earnings by monthly contracted hours before taking logs and calculating the mean
    // I am interpreting "outcome being reported as hourly" = tiposal==5. These outcomes have similar dist to other wage measures, if I do this, I get very low number for this wage type. 
    // though he might have switched "multiply"  for "divide" wrongly, but multiplying yields even wilder results. 
    
    // computing average hourly earnings:
    gen remmedr_h = remmedr/(horascontr*4.348) // contractual salary divided by the amount of contracted hours in the month
    label var remmedr_h "remuneracao media anual dividido pelo total de horas contratadas"
	

	
** Log December earnings
    
    // Compute hourly december wages:
    
    gen remdezr_h = remdezr/(horascontr*4.348) // contractual salary divided by the amount of contracted hours in the month
    label var remdezr_h "remuneracao de dezembro dividido pelo total de horas contratadas"	
	
	
	
	
// Generate variables in logs and deflated




// just for test
//
// local years " 2008 2009 2010 2011 2012 2013 2014 2015 2016"
// local ipca  " 0.643834976197206 0.671594887351247 0.711277338716318 0.757534213038901 0.80176356558955 0.849153270408197 0.903562518222102 1 1.06287988213221 1.09420743038879"
// local i=2016

local pos = `i'- 2007
local deflator : word `pos' of `ipca'
    
    * Convert salcontr_m to 2015 values using Brazil's CPI (IPCA)
    gen lr_salcontr_m = . 

    /* Wage adjustment according to year:
    */
	replace lr_salcontr_m = log(salcontr_m/`deflator') 
	 label var lr_salcontr_m "Log Salario contratual , a precos do ano de 2015"

	 
	
	
     // hourly contracted wages:
     gen lr_salcontr_h=.
	 replace lr_salcontr_h = log(salcontr_h/`deflator')
	 label var lr_salcontr_m "Log Salario contratual por hora , a precos do ano de 2015"

     
     * Deflated contracted wages
     
     
     gen r_salcontr_m=.
	 replace r_salcontr_m = salcontr_m/`deflator'
	 label var r_salcontr_m "Salario contratual, a precos de 2015"
     

     
     gen r_salcontr_h=.
	 replace r_salcontr_h = salcontr_h/`deflator'
	 label var r_salcontr_h "Salario contratual por hora, a precos de 2015"

   
    // adjuting monthly average earnings for inflation and taking logs (2015 0prices) (december ipca index)
    gen lr_remmedr = .
	replace lr_remmedr = log(remmedr/`deflator')

     
      ** Average deflated wages
     gen r_remmedr=.
	 replace r_remmedr = remmedr/`deflator'
	 

     
     //making the same for hourly average earnings:
     ** deflated hourly Average wages
     gen r_remmedr_h=.
	 replace r_remmedr_h = remmedr_h/`deflator'

     
     // adjuting hourly average earnings for inflation and taking logs (2015 0prices)
    gen lr_remmedr_h = .
	replace lr_remmedr_h = log(remmedr_h/`deflator')

    
    
    // adjust hourly dec earnings to logs and at december 2015 prices
    
       
    gen lr_remdezr_h = .
	replace lr_remdezr_h = log(remdezr_h/`deflator')

     ** Deflated December hourly earnings
     gen r_remdezr_h = .
	 replace r_remdezr_h = log(remdezr_h/`deflator')

    
    // adjust wages to logs and at december 2015 prices
    
    
    
    gen lr_remdezr = .
	replace lr_remdezr = log(remdezr/`deflator')

     ** Deflated December earnings
     gen r_remdezr = .
	 replace r_remdezr = remdezr/`deflator'

	 ** 90-10 and 50-10 wage ratio
    egen salcontr_p90 = pctile(lr_salcontr_m) , by(identificad) p(90)
    egen salcontr_p50 = pctile(lr_salcontr_m) , by(identificad) p(50)
    egen salcontr_p10 = pctile(lr_salcontr_m) , by(identificad) p(10)
	
	egen remmedr_p90 = pctile(lr_remmedr), by(identificad)p(90)
	egen remmedr_p50 = pctile(lr_remmedr), by(identificad) p(50)
	egen remmedr_p10 = pctile(lr_remmedr), by(identificad) p(10)


    gen lr_salcontr_90_10 = salcontr_p90 - salcontr_p10
    gen lr_salcontr_50_10 = salcontr_p50 - salcontr_p10
    
*
//  Select only spells that were terminated in the year according to the causadesli
*

gen quit = inlist(causadesli,10,11)
gen layoff = inlist(causadesli,20,21)


// keep employees who were active last year, but who left in the current year
keep if quit==1 & layoff==1 & dtadmissao_stata<=mdy(11,1,`i'-1)

bys PIS: gen rank_composite = horascontr + lr_remmedr_h/1000
	set seed 12345
	gen random = runiform()
	gen rank_final = rank_composite+ random/10000

* count the number of selected spells within each establishment:
sort PIS rank_final
by PIS:  egen max_rank = max(rank_final)
by PIS: gen final_rank = (rank_final == max_rank & !missing(rank_final)) 
     
     

   
 
*--------------------------------------------------------------------------------
*Part 2: Collapsing the dataset to the firm level
*--------------------------------------------------------------------------------

//drop if count_worker!=1 // only considering for average the unique PIS active in december

keep if final_rank==1	// considers only main spells of employees active throughout dec

// save an employee level dataset to homogenize municipality and industry for across year 
preserve
keep PIS identificad municipio clascnae20 year genero idade dtnascimento_stata  ocup2002 raca_cor causadesli mesdesli firm_emp ///
    grinstrucao nacionalidad portdefic tpdefic tipoadm tempempr tiposal salcontr ultrem horascontr ///
    remdezembro remmedia remdezr remmedr dtnascimento idade nacionalidad ///
     tempempr tiposal salcontr ///
     lr_remdezr lr_remmedr lr_salcontr_m lr_salcontr_h r_salcontr_m r_salcontr_h r_remmedr r_remmedr_h r_remdezr r_remdezr_h ///
     salcontr_p10 salcontr_p50 salcontr_p90 lr_salcontr_90_10 lr_salcontr_50_10 ///
	 remmedr_p10 remmedr_p50 remmedr_p90
save "$interim/worker_estab_`i'.dta", replace
restore
	



	
}


// Homogenizing municipality and induestry. Using same technique as Lagos (2021), which gets the mode at the worker x year level

// just appending year-level datasets
use "$interim/worker_estab_2010.dta",clear

forvalues k=2011/2014 {
	append using "$interim/worker_estab_`k'.dta"
	erase "$interim/worker_estab_`k'.dta" // erases year level dataset, so that it does not occupy a lot of hd space
}


// get the mode of industry category, if there are two modes, choose the smallest of the two
bys identificad: egen modeind = mode(clascnae20), minmode

// get the mode of municipality category, if there are two modes, choose the smallest of the two
bys identificad: egen modemun = mode(municipio), minmode

replace municipio=modemun
replace clascnae20=modeind

tostring year, generate(year_str)

gen cnpj_year = identificad + year_str 


compress
save "$analysis/switchers_all_years.dta", replace




