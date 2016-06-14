## load .rda
session::restore.session('data/intermediate/04-case-study-2.rda')
load('data/intermediate/03-case-study-1.rda')
load('data/intermediate/02-simulations.rda')


## save workspace
save.session('data/intermediate/05-statistical-analysis.rda', compress='xz')
 
