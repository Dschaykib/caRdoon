
logger::log_info("start API in background")
log_path <- file.path(getwd(), "temp_log")
logger::log_info("log_path: ", log_path)
log_file <- file.path(
  log_path, paste0("api_log_", format(Sys.time(), "%Y%M%d_%H%M%S"), ".txt")
  )

if (!dir.exists(log_path)) {
  logger::log_info("create log path")
  dir.create(log_path, recursive = TRUE)
}

rs <- callr::r_bg(
  func = function(log_path) {
    library(caRdoon)
    run_cardoon(
      port = 8000,
      log_path = log_path
    )
  },
  args = list(log_path = log_path),
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
