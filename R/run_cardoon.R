#' Start up caRdoon API
#'
#' @description Running this function will create the caRdoon API.
#' The API acts as a task queue with multiple workers in the background.
#'
#' @param port integer with the port, the API should run on
#'
#' @return a message, that the API has closed
#' @export
#'
run_cardoon <- function(port = 9662) {
  # TODO add loggin wihtin API on different levels (info, debug, ...)
  # TODO add number of worker as parameter
  # TODO add API path for background process
  # TODO check put this blog for plumber package structure
  # https://community.rstudio.com/t/plumber-api-and-package-structure/18099/11

  plumber::pr("R/cardoon_api.R") %>%
    plumber::pr_run(
      # manually set port
      port = port,
      # turn off visual documentation
      docs = TRUE,
      # do not display startup messages
      quiet = TRUE
    )

  return("API closed")
}

