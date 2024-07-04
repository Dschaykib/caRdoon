#' Start up caRdoon API
#'
#' @description Running this function will create the caRdoon API. The API acts
#'   as a task queue with multiple workers in the background.
#'
#' @param port integer with the port, the API should run on.
#' @param num_worker integer with number of worker processes.
#' @param check_seconds integer with number of seconds before the background
#'   process checks if the API is still alive.
#' @param sleep_time integer with the number of seconds the background process
#'   sleeps.
#' @param docs a boolean indicating if the docs should be started.
#' @param log_path a path to a file where the logs of the backend
#'  process are stored
#' @param db_name a string with the name of the DB file. Should have the suffix
#'   '.sqlite'
#' @param db_init a boolean, if TRUE the task data base is overwritten and newly
#'   initialized.
#' @param api_function a function that is evaluated at each API call.
#'
#' @import plumber
#' @import logger
#' @importFrom utils packageVersion
#'
#' @return a message, that the API has closed
#' @export
#'
run_cardoon <- function(
  port = 9662,
  num_worker = 1,
  check_seconds = 10,
  sleep_time = 5,
  docs = FALSE,
  log_path = "logs/",
  db_name = "caRdoon_task.sqlite",
  db_init = FALSE,
  api_function
  ) {

  # TODO add logging within API on different levels (info, debug, ...)
  # TODO add timestamp to logfile per default
  # TODO use file.path()
  # TODO check put this blog for plumber package structure
  # TODO check what happens to the background process if API process is killed

  # https://community.rstudio.com/t/plumber-api-and-package-structure/18099/11


  logger::log_info("caRdoon version ", as.character(packageVersion("caRdoon")))


  # validate api_function
  if (!is.function(api_function)) {
    stop("'api_function' should be an R function")
  }

  logger::log_info("set env vars for caRdoon API")
  # set the API port and number of workers as a global env, so that the
  # underlying background process knows which port to use
  Sys.setenv(CARDOON_PORT = port)
  Sys.setenv(CARDOON_NUM_WORKER = num_worker)
  Sys.setenv(CARDOON_CHECK_SECONDS = check_seconds)
  Sys.setenv(CARDOON_SLEEP_TIME = sleep_time)
  Sys.setenv(CARDOON_LOG_PATH = log_path)
  Sys.setenv(CARDOON_DB_NAME = db_name)
  Sys.setenv(CARDOON_DB_INIT = db_init)



  logger::log_info("start caRdoon API")
  plumber::plumb_api(package = "caRdoon", name = "cardoon") |>
    plumber::pr_hook(
      stage = "exit",
      # naming is done later in plumber.R
      handler =  function() {
        logger::log_info("closing DB ...")
        # DBI::dbDisconnect(cardoon_db)
        logger::log_info("closing DB done")
      }
    ) |>
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
