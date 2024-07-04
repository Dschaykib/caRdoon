
logger::log_info("start API in background")
log_path <- file.path(getwd(), "temp_log")

if (dir.exists(log_path)) {
  unlink(log_path, recursive = TRUE)
}

logger::log_info("log_path: ", log_path)
log_file <- file.path(
  log_path, paste0("api_log_", format(Sys.time(), "%Y%M%d_%H%M%S"), ".txt")
  )

if (!dir.exists(log_path)) {
  logger::log_info("create log path")
  dir.create(log_path, recursive = TRUE)
}

# simple test function
api_function <- function(id = 1, ...) {
  sleep <- runif(1) * 10 + id
  Sys.sleep(sleep)
  return(sleep)
}

rs <- callr::r_bg(
  func = function(log_path, api_function) {
    library(caRdoon)
    run_cardoon(
      port = 8000,
      log_path = log_path,
      db_name = "test_caRdoon_task.sqlite",
      db_init = TRUE,
      api_function = api_function
    )
  },
  args = list(log_path = log_path, api_function = api_function),
  package = "caRdoon",
  stdout = log_file,
  stderr = log_file,
  cmdargs = "--no-slave")
print(rs)
# wait for API to start
Sys.sleep(2)
print(rs)
stopifnot("API background job is not running" = rs$is_alive())


# tear down script
withr::defer(rs$kill(), testthat::teardown_env())
