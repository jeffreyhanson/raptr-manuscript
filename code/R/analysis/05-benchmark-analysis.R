## load session
session::restore.session("data/intermediate/00-initialization.rda")

## load parameters
benchmark_parameters <- "code/parameters/benchmark.toml" %>%
                        RcppTOML::parseTOML() %>%
                        `[[`(MODE)

## compile benchmark parameters
benchmark_combinations <- plyr::ldply(
  seq_along(benchmark_parameters$number_of_features), function(i) {
  expand.grid(
    number_features = benchmark_parameters$number_of_features[[i]],
    number_planning_units = benchmark_parameters$number_of_planning_units[[i]],
    formulation = benchmark_parameters$formulation[[i]],
    blm = benchmark_parameters$blm[[i]],
    replicate = seq_len(benchmark_parameters$replicates))
})

## configure options to show that gurobi is installed
options(GurobiInstalled = list(gurobi = TRUE, rgurobi = FALSE))

## run benchmarks
benchmark_results <- plyr::ldply(
  sample.int(nrow(benchmark_combinations)), function(i) {
  # simulate data
  curr_rd <- simulate_problem_data(
    number_features = benchmark_combinations[i, 1],
    number_planning_units = benchmark_combinations[i, 2],
    amount_target = benchmark_parameters$amount_target,
    space_target = benchmark_parameters$space_target,
    probability_of_occupancy = benchmark_parameters$occupancy_probability)
  # create unsolved problem
  curr_go <- raptr::GurobiOpts(
    MIPGap = general_parameters$MIPGap,
    Threads = general_parameters$threads,
    TimeLimit = benchmark_parameters$time_limit)
  if (benchmark_combinations[i, 3] == "unreliable") {
    curr_ru <- raptr::RapUnsolved(raptr::RapUnreliableOpts(
      BLM = benchmark_combinations[i, 4]), curr_rd)
  } else {
    curr_ru <- raptr::RapUnsolved(raptr::RapReliableOpts(
      BLM = benchmark_combinations[i, 4]), curr_rd)
  }
  # solve problems
  curr_time <- system.time({
    curr_rs <- raptr::solve(curr_ru, curr_go)
  })
  # return results
  data.frame(number_features = benchmark_combinations[i, 1],
             number_planning_units = benchmark_combinations[i, 2],
             formulation = benchmark_combinations[i, 3],
             blm = benchmark_combinations[i, 4],
             replicate = benchmark_combinations[i, 5],
             time = curr_time[["elapsed"]])
})

## save session
session::save.session("data/intermediate/05-benchmark-analysis.rda",
                      compress = "xz")
