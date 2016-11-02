 ## load .rda
checkpoint::checkpoint('2016-11-01', R.version='3.3.1', scanForPackages=FALSE)
session::restore.session('data/intermediate/05-statistical-analysis.rda')

## save workspace
save.session('data/final/results.rda', compress='xz')
