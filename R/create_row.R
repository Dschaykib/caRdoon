#' helper function to create a new row for the task queue
#'
#' @param id integer with the task identifying index
#' @param args a list of arguments for the function
#' @param result a list wiht the results of a function. This is used for
#'   reloading tasks from the DB.
#' @param state a string indicating the status of the job. Can be one of
#'   "waiting", "idle", "running" or "done"
#'
#' @return a tibble with one row
#'
#' @examples
#'
#' caRdoon:::create_row()
#' # A tibble: 1 × 7
#' #     id idle  state     args     worker result
#' #  <int> <lgl> <chr>   <list>     <list> <list>
#' #1     1 FALSE waiting <list [1]> <NULL> <NULL>
#'
create_row <- function(
    id = 1L,
    state = "waiting",
    args = NULL,
    result = NULL) {

  # create new row
  out <- tibble::tibble(
    id = id,
    idle = FALSE,
    state = state,
    args = list(args),
    worker = list(NULL),
    result = list(result)
  )
  return(out)
}
