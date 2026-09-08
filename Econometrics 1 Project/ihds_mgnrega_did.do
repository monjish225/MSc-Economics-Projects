*==============================================================
* IHDS MGNREGA & CHILD GRADE-FOR-AGE: FULL PIPELINE DO-FILE
*==============================================================

*-----------------------------
* 0. SETUP
*-----------------------------
cd "C:\Users\hello\OneDrive\Desktop\IHDS dta"
log using "work\main.log", text replace
set more off

*-----------------------------
* 1. CLEAN HOUSEHOLD FILES (MAKING IDS NUMERIC)
*-----------------------------

* 1a. 2004-05 household file
use "raw\IHDS2005\ICPSR_22626-V12\ICPSR_22626\DS0002\22626-0002-Data.dta", clear
destring IDHH IDPSU, replace ignore(" ")
save "work\hh2005_clean.dta", replace

* 1b. 2011-12 household file
use "raw\IHDS2012\ICPSR_36151-V6\ICPSR_36151\DS0002\36151-0002-Data.dta", clear
destring IDHH IDPSU, replace ignore(" ")
save "work\hh2011_clean.dta", replace

*-----------------------------
* 2. VILLAGE-LEVEL MGNREGA TREATMENT (2011-12, RURAL)
*-----------------------------
use "work\hh2011_clean.dta", clear

* Keeping rural households
tab URBAN2011
keep if URBAN2011 == 0

* Household has any MGNREGA work or income
gen hh_nrega = (NWKNREGA > 0 | INCNREGA > 0)
replace hh_nrega = 0 if hh_nrega == .
label var hh_nrega "HH has any MGNREGA work/income"

* Collapsing to village level
bysort IDPSU: egen n_hh       = count(IDHH)
bysort IDPSU: egen n_nrega_hh = total(hh_nrega)

* Village treatment dummy: 1 if any MGNREGA HH
gen treat_v = (n_nrega_hh > 0)
label var treat_v "Village has any MGNREGA HH (2011-12)"

keep IDPSU n_hh n_nrega_hh treat_v
duplicates drop

save "work\village2011_treat.dta", replace

* 3. CHILD DATA 2011-12 (POST)
use "raw\IHDS2012\ICPSR_36151-V6\ICPSR_36151\DS0001\36151-0001-Data.dta", clear

* Make IDs numeric to match hh2011_clean
destring IDHH IDPSU, replace ignore(" ")

* Merging in 2011 household info (rural/controls)
merge m:1 IDHH using "work\hh2011_clean.dta"

keep if _merge == 3
drop _merge

* Keeping rural children aged 6-14
keep if URBAN2011 == 0
keep if RO5 >= 6 & RO5 <= 14

* Gender dummy
gen girl = (RO3 == 2)
label var girl "Child is female"

* Grade variable in 2011 = ED6 (cleaning negative codes)
replace ED6 = . if ED6 < 0

* Expected grade (Class 1 at age 6 => age - 5)
gen expected_grade = RO5 - 5
replace expected_grade = 0 if expected_grade < 0
label var expected_grade "Expected grade for age (1 at age 6, etc.)"

* On-track: grade >= expected grade
gen ontrack = (ED6 >= expected_grade)
label var ontrack "Child in expected grade for age or above"
drop if missing(RO5) | missing(ED6)

* Creating generic grade variable for robustness
gen grade = ED6
label var grade "Current grade (2011)"

* Year indicator
gen year = 2011
label var year "Survey year"

* Cleaning consumption & highest adult education (HHEDUC) and harmonising name
replace COPC   = . if COPC < 0
replace HHEDUC = . if HHEDUC < 0
label var COPC   "Per capita consumption (HH19 12, 2011)"
label var HHEDUC "Highest adult education in HH, 2011"

rename HHEDUC HHED_ADULT
label var HHED_ADULT "Highest adult education in HH (harmonised)"

* Keeping relevant variables (include grade)
keep IDPSU IDHH PERSONID RO5 girl ED6 grade expected_grade ontrack ///
     STATEID DISTID URBAN2011 year COPC HHED_ADULT

destring IDHH IDPSU, replace ignore(" ")

save "work\kids2011.dta", replace

* 4. CHILD DATA 2004-05 (PRE)
use "raw\IHDS2005\ICPSR_22626-V12\ICPSR_22626\DS0001\22626-0001-Data.dta", clear

* Making IDs numeric to match hh2005_clean
destring IDHH IDPSU, replace ignore(" ")

* Merging in 2005 household info
merge m:1 IDHH using "work\hh2005_clean.dta"

keep if _merge == 3
drop _merge

* Keeping rural children aged 6-14
keep if URBAN == 0
keep if RO5 >= 6 & RO5 <= 14

* Gender dummy
gen girl = (RO3 == 2)
label var girl "Child is female"

* Grade variable in 2005 = ED5 (cleaning negative codes)
replace ED5 = . if ED5 < 0

* Expected grade and on-track
gen expected_grade = RO5 - 5
replace expected_grade = 0 if expected_grade < 0
label var expected_grade "Expected grade for age (1 at age 6, etc.)"

gen ontrack = (ED5 >= expected_grade)
label var ontrack "Child in expected grade for age or above"
drop if missing(RO5) | missing(ED5)

* Create generic grade variable for robustness
gen grade = ED5
label var grade "Current grade (2005)"

* Year indicator
gen year = 2005
label var year "Survey year"

* Cleaning consumption & highest adult education (HHED5ADULT) and harmonising name
replace COPC       = . if COPC < 0
replace HHED5ADULT = . if HHED5ADULT < 0
label var COPC       "Per capita consumption (HH19 12, 2005)"
label var HHED5ADULT "Highest adult education in HH, 2005"

rename HHED5ADULT HHED_ADULT
label var HHED_ADULT "Highest adult education in HH (harmonised)"

* Keep relevant vars (include grade)
keep IDPSU IDHH PERSONID RO5 girl ED5 grade expected_grade ontrack ///
     STATEID DISTID URBAN year COPC HHED_ADULT

destring IDHH IDPSU, replace ignore(" ")

save "work\kids2005.dta", replace

*-----------------------------
* 5. MERGING VILLAGE TREATMENT INTO CHILD DATA
*-----------------------------

* 5a. 2011 kids + treat_v
use "work\kids2011.dta", clear
merge m:1 IDPSU using "work\village2011_treat.dta"
keep if _merge == 3
drop _merge
save "work\kids2011_treat.dta", replace

* 5b. 2005 kids + treat_v (based on 2011 status)
use "work\kids2005.dta", clear
merge m:1 IDPSU using "work\village2011_treat.dta"
keep if _merge == 3
drop _merge
save "work\kids2005_treat.dta", replace

*-----------------------------
* 6. POOLED DATASET FOR DiD
*-----------------------------
use "work\kids2005_treat.dta", clear
append using "work\kids2011_treat.dta"

gen post = (year == 2011)
label var post "Post-period (1=2011-12, 0=2004-05)"

* Grade gap robustness outcome
gen gradegap = grade - expected_grade if !missing(grade, expected_grade)
label var gradegap "Grade - expected grade-for-age (grade gap)"

save "work\kids_pooled_village_treat.dta", replace

*-----------------------------
* 7. DiD REGRESSIONS WITH CONTROLS + BALANCE & STATE FE
*-----------------------------
use "work\kids_pooled_village_treat.dta", clear

* Age controls
gen age  = RO5
gen age2 = age^2
label var age  "Child age in years"
label var age2 "Child age squared"

* ----- Baseline balance table: 2005 only -----
preserve
keep if year == 2005
tabstat age girl ontrack COPC HHED_ADULT, ///
        by(treat_v) statistics(mean sd n)
restore

* ----- Balance table: 2011 only (robustness / descriptive) -----
preserve
keep if year == 2011
tabstat age girl ontrack COPC HHED_ADULT, ///
        by(treat_v) statistics(mean sd n)
restore

* 7a. DiD with age, COPC, HHED_ADULT + STATE dummies (no gender)
reg ontrack i.treat_v##i.post ///
    c.age c.age2 ///
    c.COPC ///
    c.HHED_ADULT ///
    i.STATEID, cluster(IDPSU)

* 7b. DiD with gender as additional control (still with STATE dummies)
reg ontrack i.treat_v##i.post ///
    i.girl ///
    c.age c.age2 ///
    c.COPC ///
    c.HHED_ADULT ///
    i.STATEID, cluster(IDPSU)

* 7c. Gender-heterogeneous DiD (triple interaction) + STATE dummies
reg ontrack i.treat_v##i.post##i.girl ///
    c.age c.age2 ///
    c.COPC ///
    c.HHED_ADULT ///
    i.STATEID, cluster(IDPSU)

* DiD effect for girls specifically:
lincom 1.treat_v#1.post + 1.treat_v#1.post#1.girl

*-----------------------------
* 8. ROBUSTNESS: grade gap as outcome
*-----------------------------
reg gradegap i.treat_v##i.post ///
    i.girl ///
    c.age c.age2 ///
    c.COPC ///
    c.HHED_ADULT ///
    i.STATEID, cluster(IDPSU)

*-----------------------------
* 9. RAW DiD MEANS TABLE
*-----------------------------
preserve
collapse (mean) ontrack, by(treat_v post)
list, sepby(treat_v)
restore

*-----------------------------
* END
*-----------------------------
log close
