#' Start up caRdoon API
#'
#' @description Running this function will create the caRdoon API.
#' The API acts as a task queue with multiple workers in the background.
#'
#' @param port integer with the port, the API should run on
#' @param docs a boolean indicating if the docs should be started
#'
#' @import R6
#' @import plumber
#' @import callr
#' @import httr
#'
#' @return a message, that the API has closed
#' @export
#'
run_cardoon <- function(
    port = 9662,
    docs = FALSE) {
  # TODO add logging wihtin API on different levels (info, debug, ...)
  # TODO add number of worker as parameter
  # TODO add API path for background process
  # TODO check put this blog for plumber package structure
  # https://community.rstudio.com/t/plumber-api-and-package-structure/18099/11

# path_fkt <- file.path(system.file(package = "caRdoon"),
#                       "R", "cardoon_api.R")
  path_fkt <- "inst/plumber/cardoon_api.R"
  print(path_fkt)
  # plumber::pr(path_fkt) %>%
  plumber::plumb_api(package = "caRdoon", name = "cardoon") %>%
    plumber::pr_run(
      # manually set port
      port = port,
      # turn off visual documentation
      docs = docs,
      # do not display start up messages
      quiet = TRUE
    )

  return("API closed")
}

