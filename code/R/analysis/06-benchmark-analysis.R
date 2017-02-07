## load .rda
checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE)
session::restore.session('data/intermediate/05-statistical-analysis.rda')

## load parameeters
benchmark.params.LST <- parseTOML('code/parameters/benchmark.toml')

## set benchmark parameter combinations
benchmark.params.DF1 <- expand.grid(number.features=benchmark.params.LST[[MODE]][['number.of.features']],
  number.planning.units=benchmark.params.LST[[MODE]][['number.of.planning.units']],
  replicate=seq_len(benchmark.params.LST[[MODE]][['replicates']]))

benchmark.params.DF2 <- expand.grid(formulation=c('unreliable', 'reliable'), blm=benchmark.params.LST[[MODE]]$blm )
  
## run benchmark analysis
benchmark.results.DF <- ldply(sample.int(nrow(benchmark.params.DF1)), function(i) {
  # simulate data
  curr.rd <- simulate.problem.data(
    number.features=benchmark.params.DF1[i,1],
    number.planning.units=benchmark.params.DF1[i,2],
    amount.target=benchmark.params.LST[[MODE]]$amount.target,
    space.target=benchmark.params.LST[[MODE]]$space.target,
    probability.of.occupancy=benchmark.params.LST[[MODE]]$occupancy.probability
  )
  curr.go <- GurobiOpts(MIPGap=general.params.LST[[MODE]][['MIPGap']],
    Threads=general.params.LST[[MODE]][['threads']])
  
  ldply(seq_len(nrow(benchmark.params.DF2)), function(j) {
    if (benchmark.params.DF2[[1]][j]=='unreliable') {
      curr.ru <- RapUnsolved(RapUnreliableOpts(BLM=benchmark.params.DF2[[2]][j]), curr.rd)
    } else {
      curr.ru <- RapUnsolved(RapReliableOpts(BLM=benchmark.params.DF2[[2]][j]), curr.rd)
    }
    curr.time <- system.time({curr.rs <- solve(curr.ru, curr.go)})
    data.frame(
      formulation=benchmark.params.DF2[[1]][j],
      number.features=benchmark.params.DF1[i,1],
      number.planning.units=benchmark.params.DF1[i,2],
      replicate=benchmark.params.DF1[i,3],
      blm=benchmark.params.DF2[[2]][j],
      time=curr.time[['elapsed']]
    )
  })
}) 
  
## save workspace
save.session('data/intermediate/06-benchmark-analysis.rda', compress='xz')

