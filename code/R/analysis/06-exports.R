 ## load .rda
session::restore.session('data/intermediate/05-statistical-analysis.rda')
checkpoint(general.params.LST[[MODE]]$checkpoint_date, R.version=general.params.LST[[MODE]]$checkpoint_R_version, scanForPackages=FALSE)



## save workspace
save.session('data/final/results.rda', compress='xz')
