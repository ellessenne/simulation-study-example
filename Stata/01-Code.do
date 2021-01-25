// With this script, we see how to setup and run a simulation study.
// Details on the study are included in the README file of this repository.

* 1- Start small, as a proof-of-concept

* Simulating a confounder
clear
set obs 10000
gen Z = rnormal()

* Simulating an exposure
local gamma0 = 1
local gamma1 = 3
gen PX = 1 / (1 + exp(-(`gamma0' + `gamma1' * Z)))
gen X = rbinomial(1, PX)
drop PX

* Simulating an outcome
local alpha0 = 10
local alpha1 = 5
gen Y = rnormal(`alpha0' + `alpha1' * Z)

* Check simulated data
list in 1/10
summ

* Then, we fit two models:
* 1. A model that ignores the confounder
regress Y X
estimates store m1
* 2. A model that adjust for the confounder
regress Y X Z
estimates store m2

* Then, we compare the treatment effect estimate side by side
estimates tab m1 m2
* As expected, the estimate of X from m1 is biased
* Remember: X and Y are independent, so the treatment effect should be zero!
* This is, in principle, what we should repeat B times in our simulation study

* 2- Now, start generalising the experiment above
*    We use (and recommend) the RightWay™ approach described here:
*    - https://github.com/tpmorris/TheRightWay
*    - https://ideas.repec.org/p/boc/usug19/07.html

* The first step consists of defining a program that simulates data and run an analysis
capture program drop simstudy
program define simstudy, rclass
    version 14
    syntax [ , nobs(integer 100) gamma0(real 1) gamma1(real 3) alpha0(real 10) alpha1(real 5)]
	* Here we copy the code we developed above
	* First, to generate data:
	clear
	quietly set obs `nobs'
	gen Z = rnormal()
	* Simulating an exposure
	gen PX = 1 / (1 + exp(-(`gamma0' + `gamma1' * Z)))
	gen X = rbinomial(1, PX)
	drop PX
	* Simulating an outcome
	gen Y = rnormal(`alpha0' + `alpha1' * Z)
	* Then, run the analysis methods
	* Model 1:
	quietly regress Y X
	return scalar Xbeta_est_m1 = _b[X]
	return scalar Xbeta_se_m1 = _se[X]
	* Model 2:
	quietly regress Y X Z
	return scalar Xbeta_est_m2 = _b[X]
	return scalar Xbeta_se_m2 = _se[X]
end

* We test it
simstudy
return list

* Seems ok, hence we now create a postfile to store the results for each iteration...
postfile res int(i) float(dgm) byte(model) float(estimate se) using data/res.dta, replace

* We set a seed for reproducibility
* You could also store the random seed at each generation, you
* can find an example here: https://github.com/tpmorris/TheRightWay
set seed 2394756

local B = 10000
local N = 200
noi _dots 0, title("Simulation running...")
forval i = 1/`B' {
    foreach dgm of numlist 1 2 {
		if (`dgm' == 1) {
			simstudy, nobs(`N') alpha1(5)
		}
		else if (`dgm' == 2) {
			simstudy, nobs(`N') alpha1(0)
		}
		post res (`i') (`dgm') (1) (r(Xbeta_est_m1)) (r(Xbeta_se_m1))
		post res (`i') (`dgm') (2) (r(Xbeta_est_m2)) (r(Xbeta_se_m2))
	}
    noi _dots `i' 0
}
postclose res

* Ok, done!
* We now label the estimates data and re-save
use data/res.dta, clear
label variable i "Rep num"
label variable dgm "DGM"
label variable model "Model"
label variable estimate "θᵢ"
label variable se "SE(θᵢ)"
label define dgmlab 1 "DGM=1" 2 "DGM=2"
label values dgm dgmlab
label define modellab 1 "Model=1" 2 "Model=2"
label values model modellab
sort i dgm model

* Let's check the labelled estimates
list in 1/20, noobs sepby(i)

* Then, compress and export
compress
save data/res.dta, replace
