// With this script, we see how to analyse the simulation study run (and exported)
// using the script '01-Code.do'.
// Details on the study are included in the README file of this repository.

* 1- We start by importing the dataset with the results of our study:
use data/res.dta, clear

* 2- Let's inspect our dataset:
list in 1/20
* We can use any other tool you might like/know
summ

* It's important to note the format of our dataset:
* In this case, it's in long format (one observation per row), but it might be in
* wide format too (depending on how you structured your data)
* Either way, you can use any tool to reshape the data any way you want,
* e.g. reshape long/wide
* For instance, Stata often likes things to be in wide format:
reshape wide estimate se, i(i dgm) j(model)

* 3- We could then plot some variables, e.g. for a given method or DGM:

* With a histogram:
hist estimate1 if dgm == 1
hist estimate2 if dgm == 1

* With a scatterplot e.g. to compare methods for a given DGM
twoway scatter estimate1 estimate2 if dgm == 1

* We do this to:
* - Check potential outliers
* - Check the potential correlation between methods
* - Get a 'grasp' of our data

* 4- Now, we could calculate some summary statistics for our observed data,
*    e.g. after grouping our data with bysort:
bysort dgm: summ estimate1 se1 estimate2 se2
* Here we can see mean and SDs of point estimates and standard errors

* We can also e.g. calculate bias:
gen bias1 = estimate1 - 0
gen bias2 = estimate2 - 0
* Here '0' is the true value of the parameter
bysort summ: summ bias1 bias2
* ...which here is the same as before, but only because the true value is zero

* 5- All of the above (and much more) can be automated and
*    streamlined by using the simsum command.
*    If not installed, download it from SSC via:
*    . ssc install simsum 
simsum estimate*, true(0) id(i) by(dgm) se(se*)

* We can get Monte Carlo standard errors easily by using the mcse option
simsum estimate*, true(0) id(i) by(dgm) se(se*) mcse
