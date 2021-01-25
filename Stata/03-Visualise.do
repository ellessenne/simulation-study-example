// With this script, we see how to visualise results from the simulation study
// run (and exported) using the script '01-Code.do' and analysed with '02-Analyse.do'.
// Details on the study are included in the README file of this repository.

* 1- We start by importing the dataset with the results of our study:
use data/res.dta, clear

* 2- Then, we summarise the study once again using simsum:
simsum estimate, true(0) id(i) methodvar(model) by(dgm) se(se) mcse
* Here we analyse the dataset in long format, so we don't need to 
* reshape wide our data.

* 3- Now, we can obtain a variety of plots to summarise our data
*    Here we actually need to reshape wide, that makes our life easier...  
reshape wide estimate se, i(i dgm) j(model)

* Plots for the point estimates (and SEs)
twoway scatter estimate1 estimate2, by(dgm)
twoway scatter se1 se2, by(dgm)
twoway scatter estimate1 se1, by(dgm)
twoway scatter estimate1 se2, by(dgm)

* Let's re-import the data and re-run simsum:
use data/res.dta, clear
simsum estimate, true(0) id(i) methodvar(model) by(dgm) se(se) mcse clear
* Using the 'clear' option we load the performance measures in memory

* We can now plot some of that, e.g.:
twoway (scatter estimate1 dgm if perfmeascode == "bias") (scatter estimate2 dgm if perfmeascode == "bias") 
twoway (scatter estimate1 dgm if perfmeascode == "power") (scatter estimate2 dgm if perfmeascode == "power") 

* These example plots are not great and require a lots of custom coding to _get right_.
* You can find lots of code to create relevant plots in Stata here:
* https://github.com/tpmorris/simtutorial/blob/master/Stata

* My personal suggestion would be to run and analyse the simulation study 
* in Stata and then create some visualisations using R, which has more
* advanced plotting capabilities.
