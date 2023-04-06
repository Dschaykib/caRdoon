#' Start up caRdoon API
#'
#' @description Running this function will create the caRdoon API.
#' The API acts as a task queue with multiple workers in the background.
#'
#' @param port integer with the port, the API should run on
#' @param num_worker integer with number of worker processes
#' @param check_seconds integer with number of seconds before the background process checks if the API is still alive
#' @param sleep_time integer with the number of seconds the background process sleeps
#' @param docs a boolean indicating if the docs should be started
#'
#' @import plumber
#' @import logger
#'
#' @return a message, that the API has closed
#' @export
#'
run_cardoon <- function(
    port = 9662,
    num_worker = 1,
    check_seconds = 60,
    sleep_time = 10,
    docs = FALSE) {
  # TODO add logging wihtin API on different levels (info, debug, ...)
  # TODO add number of worker as parameter
  # TODO add API path for background process
  # TODO check put this blog for plumber package structure
  # https://community.rstudio.com/t/plumber-api-and-package-structure/18099/11

  logger::log_info("set env vars for caRdoon API")
  # set the API port and number of workers as a global env, so that the
  # underlying background process knows which port to use
  Sys.setenv(CARDOON_PORT = port)
  Sys.setenv(CARDOON_NUM_WORKER = num_worker)
  Sys.setenv(CARDOON_CHECK_SECONDS = check_seconds)
  Sys.setenv(CARDOON_SLEEP_TIME = sleep_time)

# path_fkt <- file.path(system.file(package = "caRdoon"),
#                       "R", "cardoon_api.R")
  #path_fkt <- "inst/plumber/cardoon_api.R"
  #print(path_fkt)
  # plumber::pr(path_fkt) %>%
  logger::log_info("start caRdoon API")
  plumber::plumb_api(package = "caRdoon", name = "cardoon") %>%
    plumber::pr_run(
      # manually set port
      port = port,
      # turn off visual documentation
      docs = docs,
      # do not display start up messages
      quiet = TRUE
    )
  logger::log_info("end caRdoon API")
  return("API closed")
}

