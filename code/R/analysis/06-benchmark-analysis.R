## load .rda
checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE)
session::restore.session('data/intermediate/05-statistical-analysis.rda')

## load parameeters
benchmark.params.LST <- parseTOML('code/parameters/benchmark.toml')

## run benchmark analysis for unreliable formulation
unreliable.benchmark.params.DF <- expand.grid(number.features=benchmark.params.LST[[MODE]][['unreliable.number.of.features']],
  number.planning.units=benchmark.params.LST[[MODE]][['unreliable.number.of.planning.units']],
  replicate=seq_len(benchmark.params.LST[[MODE]][['replicates']]))

unreliable.benchmark.DF <- ldply(sample.int(nrow(unreliable.benchmark.params.DF)), function(i) {
  # simulate data
  source('code/R/functions/simulate.R')
  curr.rd <- simulate.problem.data(
    number.features=unreliable.benchmark.params.DF[i,1],
    number.planning.units=unreliable.benchmark.params.DF[i,2],
    amount.target=benchmark.params.LST[[MODE]]$amount.target,
    space.target=benchmark.params.LST[[MODE]]$space.target,
    probability.of.occupancy=benchmark.params.LST[[MODE]]$occupancy.probability
  )
  curr.go <- GurobiOpts(MIPGap=general.params.LST[[MODE]][['MIPGap']],
    Threads=general.params.LST[[MODE]][['threads']])
  
  ldply(benchmark.params.LST[[MODE]]$blm, function(j) {
    curr.ru <- RapUnsolved(RapUnreliableOpts(BLM=j), curr.rd)
    curr.time <- system.time({curr.rs <- solve(curr.ru, curr.go)})
    data.frame(
      number.features=unreliable.benchmark.params.DF[i,1],
      number.planning.units=unreliable.benchmark.params.DF[i,2],
      blm=j,
      replicate=unreliable.benchmark.params.DF[i,3],
      time=curr.time[['elapsed']]
    )
  })
})  
  
## run benchmark analysis for reliable formulation
reliable.benchmark.params.DF <- expand.grid(number.features=benchmark.params.LST[[MODE]][['reliable.number.of.features']],
  number.planning.units=benchmark.params.LST[[MODE]][['reliable.number.of.planning.units']],
  replicate=seq_len(benchmark.params.LST[[MODE]][['replicates']]))

reliable.benchmark.DF <- ldply(sample.int(nrow(reliable.benchmark.params.DF)), function(i) {
  # simulate data
  curr.rd <- simulate.problem.data(
    number.features=reliable.benchmark.params.DF[i,1],
    number.planning.units=reliable.benchmark.params.DF[i,2],
    amount.target=benchmark.params.LST[[MODE]]$amount.target,
    space.target=benchmark.params.LST[[MODE]]$space.target,
    probability.of.occupancy=benchmark.params.LST[[MODE]]$occupancy.probability
  )
  curr.go <- GurobiOpts(MIPGap=general.params.LST[[MODE]][['MIPGap']],
    Threads=general.params.LST[[MODE]][['threads']])
  
  ldply(benchmark.params.LST[[MODE]]$blm, function(j) {
    curr.ru <- RapUnsolved(RapReliableOpts(BLM=j), curr.rd)
    curr.time <- system.time({curr.rs <- solve(curr.ru, curr.go)})
    data.frame(
      number.features=reliable.benchmark.params.DF[i,1],
      number.planning.units=reliable.benchmark.params.DF[i,2],
      blm=j,
      replicate=reliable.benchmark.params.DF[i,3],
      time=curr.time[['elapsed']]
    )
  })
})  

## combine results
benchmark.DF <- unreliable.benchmark.DF %>% 
  mutate(formulation='unreliable') %>%
  rbind(reliable.benchmark.DF %>% mutate(formulation='reliable'))

## save workspace
save.session('data/intermediate/06-benchmark-analysis.rda', compress='xz')

