 ## load session
session::restore.session("data/intermediate/06-statistical-analysis.rda")

## save workspace
session::save.session("data/final/results.rda", compress = "xz")
