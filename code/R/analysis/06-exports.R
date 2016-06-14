 ## load .rda
session::restore.session('data/intermediate/05-statistical-analysis.rda')



## save workspace
save.session('data/final/results.rda', compress='xz')
