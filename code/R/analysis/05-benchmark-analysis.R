## load .rda
checkpoint::checkpoint('2016-11-26', R.version='3.3.2', scanForPackages=FALSE)
session::restore.session('data/intermediate/00-initialization.rda')

## load parameters
benchmark.params.LST <- parseTOML('code/parameters/benchmark.toml')

# load simulation functions
source('code/R/functions/simulate.R')

## compile benchmark parameters
benchmark.params.DF <- ldply(seq_along(benchmark.params.LST[[MODE]][['number.of.features']]), function(i) {
  expand.grid(number.features=benchmark.params.LST[[MODE]][['number.of.features']][[i]],
    number.planning.units=benchmark.params.LST[[MODE]][['number.of.planning.units']][[i]],
    formulation = benchmark.params.LST[[MODE]][['formulation']],
    blm = benchmark.params.LST[[MODE]][['blm']],
    replicate = seq_len(benchmark.params.LST[[MODE]][['replicates']]))
  }
)

benchmark.DF <- ldply(benchmark.params.DF, function(i) {
  # simulate data
  curr.rd <- simulate.problem.data(
    number.features=benchmark.params.DF[i,1],
    number.planning.units=benchmark.params.DF[i,2],
    amount.target=benchmark.params.LST[[MODE]]$amount.target,
    space.target=benchmark.params.LST[[MODE]]$space.target,
    probability.of.occupancy=benchmark.params.LST[[MODE]]$occupancy.probability
  )
  # create unsolved problem
  curr.go <- GurobiOpts(MIPGap=general.params.LST[[MODE]][['MIPGap']],
    Threads=general.params.LST[[MODE]][['threads']])
  if (benchmark.params.DF[i,3] == "unreliable") {
    curr.ru <- RapUnsolved(RapUnreliableOpts(BLM=benchmark.params.DF[i,4]), curr.rd)
  } else {
    curr.ru <- RapUnsolved(RapReliableOpts(BLM=benchmark.params.DF[i,4]), curr.rd)
  }
  # solve problems
  curr.time <- system.time({curr.rs <- solve(curr.ru, curr.go)})
  # return results
  data.frame(
    number.features=benchmark.params.DF[i,1],
    number.planning.units=benchmark.params.DF[i,2],
    formulation=benchmark.params.DF[i,3],
    blm=benchmark.params.DF[i,4],
    replicate=benchmark.params.DF[i,5],
    time=curr.time[['elapsed']]
  )
})

## save workspace
save.session('data/intermediate/05-benchmark-analysis.rda', compress='xz')
