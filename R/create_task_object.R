#' Create R6 task list object
#'
#'
#' @description The process and details for this R6 class can be found
#'   (here)[https://www.tidyverse.org/blog/2019/09/callr-task-q/].
#'
#' @param num_worker integer, the number of worker processes
#'
#' @import R6
#' @import callr
#' @import httr
#' @import logger
#' @import processx
#' @import tibble
#' @import DBI
#' @import RSQLite
#'
#' @return an R6 object to track and queue tasks
#'
create_task_object <- function(num_worker = 1L) {

  # add to avoids notes in package checks
  private <- NA
  self <- NA


  # setup database ----------------------------------------------------------

  # TODO maybe add pool package
  logger::log_info("Connect to 'caRdoon_task.sqlite'")
  cardoon_db <- DBI::dbConnect(RSQLite::SQLite(), "caRdoon_task.sqlite")

  # create empty db format for initialization
  empty_db <- data.frame(
    id = NA_integer_,
    idle = NA,
    state = NA_character_,
    fun = NA_character_,
    args = NA_character_,
    worker = NA_character_,
    result = NA_character_
  )[0,]

  db_list <- DBI::dbListTables(cardoon_db)
  if ( length(db_list) == 0 ) {
    logger::log_info("create inital DB file")
    DBI::dbWriteTable(cardoon_db, "tasks", empty_db)
  } else {
    logger::log_info("DB 'tasks' found - load for intial queue")
  }

  task_db <- DBI::dbReadTable(cardoon_db, "tasks")

  # rawToChar(serialize("", ascii = TRUE, connection = NULL))
  # unserialize(charToRaw())

# setup q-object ----------------------------------------------------------


  logger::log_info("create R6 object for tasks queue")
  task_q <- R6::R6Class(
    "task_q",
    public = list(
      initialize = function(concurrency = num_worker) {
        private$start_workers(concurrency)
        invisible(self)

        # add initital tasks
        lapply(
          X = seq_len(nrow(task_db)),
          FUN = function(i_task, task_db) {
            self$push(
              fun = unserialize(charToRaw(task_db$fun[i_task])),
              args = unserialize(charToRaw(task_db$args[i_task])),
              id = task_db$id[i_task]
              )
            },
          task_db = task_db
        )
      },
      list_tasks = function() private$tasks,
      get_num_waiting = function()
        sum(!private$tasks$idle & private$tasks$state == "waiting"),
      get_num_running = function()
        sum(!private$tasks$idle & private$tasks$state == "running"),
      get_num_done = function() sum(private$tasks$state == "done"),
      is_idle = function() sum(!private$tasks$idle) == 0,

      push = function(fun, args = list(), id = NULL) {
        if (is.null(id)) id <- private$get_next_id()
        if (id %in% private$tasks$id) stop("Duplicate task id")
        before <- which(private$tasks$idle)[1]
        private$tasks <- tibble::add_row(
          private$tasks, .before = before,
          id = id, idle = FALSE, state = "waiting", fun = list(fun),
          args = list(args), worker = list(NULL), result = list(NULL)
          )
        private$schedule()
        invisible(id)
      },

      poll = function(timeout = 0) {
        limit <- Sys.time() + timeout
        as_ms <- function(x) if (x == Inf) -1L else as.integer(x)
        repeat{
          topoll <- which(private$tasks$state == "running")
          conns <- lapply(
            private$tasks$worker[topoll],
            function(x) x$get_poll_connection())
          pr <- processx::poll(conns, as_ms(timeout))
          private$tasks$state[topoll][pr == "ready"] <- "ready"
          private$schedule()
          ret <- private$tasks$id[private$tasks$state == "done"]
          if (is.finite(timeout)) timeout <- limit - Sys.time()
          if (length(ret) || timeout < 0) break;
        }
        ret
      },

      pop = function(timeout = 0) {
        if (is.na(done <- self$poll(timeout)[1])) return(NULL)
        row <- match(done, private$tasks$id)
        result <- private$tasks$result[[row]]
        private$tasks <- private$tasks[-row, ]
        c(result, list(task_id = done))
      }
    ),

    private = list(
      tasks = NULL,
      next_id = nrow(task_db) + 1L,
      get_next_id = function() {
        id <- private$next_id
        private$next_id <- id + 1L
        paste0(".", id)
      },

      start_workers = function(concurrency) {
        private$tasks <- tibble::tibble(
          id = character(), idle = logical(),
          state = c("waiting", "running", "ready", "done")[NULL],
          fun = list(), args = list(), worker = list(), result = list())
        for (i in seq_len(concurrency)) {
          rs <- callr::r_session$new(wait = FALSE)
          private$tasks <- tibble::add_row(
            private$tasks,
            id = paste0(".idle-", i), idle = TRUE, state = "running",
            fun = list(NULL), args = list(NULL), worker = list(rs),
            result = list(NULL))
        }
      },

      schedule = function() {
        ready <- which(private$tasks$state == "ready")
        if (!length(ready)) return()
        rss <- private$tasks$worker[ready]

        private$tasks$result[ready] <- lapply(rss, function(x) x$read())
        private$tasks$worker[ready] <- replicate(length(ready), NULL)
        private$tasks$state[ready] <-
          ifelse(private$tasks$idle[ready], "waiting", "done")

        waiting <- which(private$tasks$state == "waiting")[1:length(ready)]
        private$tasks$worker[waiting] <- rss
        private$tasks$state[waiting] <-
          ifelse(private$tasks$idle[waiting], "ready", "running")
        lapply(waiting, function(i) {
          if (! private$tasks$idle[i]) {
            private$tasks$worker[[i]]$call(private$tasks$fun[[i]],
                                           private$tasks$args[[i]])
          }
        })
      }
    )
  )

  return(task_q)
}
