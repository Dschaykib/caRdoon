#' Function to periodically call the API's endpoint to keep the queue moving
#'
#' @details When the API is not alive anymore, this process is terminated after
#'   a number of retries.
#'
#'
#' @param api_path string with the path to the API.
#' @param check_seconds integer with number of seconds before the background
#'   process checks if the API is still alive. See Details.
#' @param sleep_time integer with the number of seconds the background process
#'   sleeps before triggering the API's queue again.
#' @param retry number of consecutive failed retries before the process is
#'   terminated.
#'
#' @import logger
#'
#' @return no actual return value
create_background_process <- function(
  api_path,
  check_seconds = 60,
  sleep_time = 10,
  retry = 5
) {


  logger::log_info("initialise caRdoon background process")
  # setup time to initialize API
  Sys.sleep(2)

  # setup to check if API is still running
  check_api <- function() {
    tryCatch({
      tmp_call <- httr::GET(paste0(api_path, "/ping"))
      # return value of ping (should be TRUE)
      httr::content(tmp_call)[[1]]
    },
    error = function(e) FALSE)
  }
  is_alive <- TRUE
  check_time <- Sys.time()
  current_try <- 1

  # loop for constant checks, to keep process updating
  logger::log_info("listening to: ", api_path)
  logger::log_info("start caRdoon background process loop")
  last_msg <- ""
  this_msg <- ""
  while (current_try <= retry) {
    Sys.sleep(sleep_time)
    check <- tryCatch({
      httr::GET(paste0(api_path, "/nextJob"))
    },
    error = function(e) e)

    if (length(check$message) > 0 ) {
      this_msg <- check$message
    }
    if (last_msg != this_msg) {
      logger::log_info("last msg: ", this_msg)
      last_msg <- this_msg
    }

    # update is_alive every x seconds
    if (Sys.time() > (check_time + check_seconds)) {
      check_time <- Sys.time()
      is_alive <- check_api()
      logger::log_info(paste0(current_try, " / ", retry,
                              " check if API is alive: ", is_alive))
      if (is_alive) {
        current_try <- 1
      } else {
        current_try <- current_try + 1
      }
    }

  }
  logger::log_info("end caRdoon background process loop")
}
