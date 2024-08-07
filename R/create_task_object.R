#' Create R6 task list object
#'
#'
#' @description The process and details for this R6 class can be found
#'   (here)[https://www.tidyverse.org/blog/2019/09/callr-task-q/].
#'
#' @param num_worker integer, the number of worker processes
#' @param db_name a string with the name of the DB file. Should have the suffix
#'   '.sqlite'
#' @param db_init a boolean, if TRUE the task data base is overwritten and newly
#'   initialized.
#' @param api_function function that is used and evaluated in each api call
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
create_task_object <- function(
    num_worker = 1L,
    db_init = FALSE,
    db_name = "caRdoon_task.sqlite",
    api_function) {

  # add to avoids notes in package checks
  private <- NA
  self <- NA


  # setup database ----------------------------------------------------------

  # TODO maybe add pool package
  logger::log_info("Connect to '", db_name, "'")
  cardoon_db <- DBI::dbConnect(RSQLite::SQLite(), db_name)
  #cardoon_db <- DBI::dbConnect(RSQLite::SQLite(),"inst/plumber/cardoon/caRdoon_task.sqlite")


  db_list <- DBI::dbListTables(cardoon_db)
  if (length(db_list) == 0 || !("tasks" %in% db_list) || db_init) {
    logger::log_info("create inital DB table 'tasks'")
    DBI::dbWriteTable(
      conn = cardoon_db,
      name = "tasks",
      value = create_db_row(create_row())[0, ],
      overwrite = db_init)
  } else {
    logger::log_info("DB with 'tasks' found - load for intial queue")
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
      },
      list_tasks = function() private$tasks,
      get_num_waiting = function() {
        sum(!private$tasks$idle & private$tasks$state == "waiting")
      },
      get_num_running = function() {
        sum(!private$tasks$idle & private$tasks$state == "running")
      },
      get_num_done = function() sum(private$tasks$state == "done"),
      is_idle = function() sum(!private$tasks$idle) == 0,

      push = function(args = list(),
                      result = NULL,
                      id = NULL,
                      add_db = TRUE,
                      state = "waiting") {
        if (is.null(id)) id <- private$get_next_id()
        if (id %in% private$tasks$id) stop("Duplicate task id")
        before <- which(private$tasks$idle)[1]
        # case when tasks are empty, but db initial tasks are loaded
        # set before to default NULL
        if (is.na(before)) before <- NULL

        # add row to DB and use empty_db function to create a new row
        new_row <- create_row(
          id = id,
          args = args,
          result = result,
          state = state)
        if (add_db) {
          new_db_row <- create_db_row(new_row)
          logger::log_info("-- debug: add row to db in push")
          DBI::dbAppendTable(cardoon_db, "tasks", new_db_row)
        }

        private$tasks <- tibble::add_row(
          private$tasks,
          .before = before,
          new_row
        )

        # TODO needs ordering and fixing?
        # private$tasks <- rbind(private$tasks, new_row)

        logger::log_info("rows in tasks: ", nrow(private$tasks))


        private$schedule()
        invisible(id)
      },

      poll = function(timeout = 0) {
        limit <- Sys.time() + timeout
        as_ms <- function(x) if (x == Inf) -1L else as.integer(x)
        logger::log_info("-- debug: within poll")
        repeat {
          topoll <- which(private$tasks$state == "running")
          conns <- lapply(
            private$tasks$worker[topoll],
            function(x) x$get_poll_connection())
          pr <- processx::poll(conns, as_ms(timeout))


          private$tasks$state[topoll][pr == "ready"] <- "ready"

          # TODO maybe add check for status "timeout" too

          private$schedule()
          ret <- private$tasks$id[private$tasks$state == "done"]
          if (is.finite(timeout)) timeout <- limit - Sys.time()
          if (length(ret) || timeout < 0) break
        }
        return(ret)
      },

      pop = function(timeout = 0) {
        done <- self$poll(timeout)[1]
        if (is.na(done)) return(NULL)
        row <- match(done, private$tasks$id)
        result <- private$tasks$result[[row]]
        out <- c(result, list(task_id = done))
        return(out)
      }
    ),

    private = list(
      tasks = NULL,
      next_id = nrow(task_db) + 1L,
      get_next_id = function() {
        id <- private$next_id
        private$next_id <- id + 1L
        # paste0(".", id)
        return(id)
      },

      start_workers = function(concurrency) {
        logger::log_info("initialize tasks from DB with ",
                         nrow(task_db), " tasks")
        private$tasks <- create_row(state = character(0))
        # add initial tasks from DB
        lapply(
          X = seq_len(nrow(task_db)),
          FUN = function(i_task, task_db) {

            # only for "done" jobs the state is set
            # all others are recalculated: "waiting"
            this_state <- ifelse(
              test = task_db$state[i_task] == "done",
              yes =  "done",
              no =  "waiting")

            self$push(
              args = unserialize(charToRaw(task_db$args[i_task]))[[1]],
              result = unserialize(charToRaw(task_db$result[i_task]))[[1]],
              id = task_db$id[i_task],
              add_db = FALSE,
              state = this_state
            )
          },
          task_db = task_db
        )


        logger::log_info("start ", concurrency, " workers")
        for (i in seq_len(concurrency)) {
          rs <- callr::r_session$new(wait = FALSE)

          # negative id for worker nodes
          private$tasks <- tibble::add_row(
            private$tasks,
            id = -i,
            idle = TRUE,
            state = "running",
            args = list(NULL),
            worker = list(rs),
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

        waiting <- which(private$tasks$state == "waiting")[seq_along(ready)]
        private$tasks$worker[waiting] <- rss
        private$tasks$state[waiting] <-
          ifelse(private$tasks$idle[waiting], "ready", "running")

        # DONE add update SQL function
        # - result
        # - state
        # - worker (not needed)
        updates <- unique(c(ready, waiting))

        # case when only idle jobs are left
        # 'ready' and 'waiting' are then the same
        if ((length(ready) == length(waiting)) &
            (all(ready %in% waiting) & all(waiting %in% ready))) {

          updates <- c()
        }
        logger::log_info(
          "schedule: update ", length(updates), " row in DB task-table"
        )

        for (i_update in updates) {
          this_set <- list(
            state = private$tasks$state[i_update],
            result = rawToChar(
              serialize(
                object = private$tasks$result[i_update],
                ascii = TRUE,
                connection = NULL
              )
            )

          )
          this_update <- db_update_row(
            con = cardoon_db,
            tablename = "tasks",
            key = list(id = private$tasks$id[i_update]),
            set = this_set
          )
          logger::log_info(
            "update id ", private$tasks$id[i_update], ": ", this_update
          )

        }

        lapply(waiting, function(i) {
          if (!private$tasks$idle[i]) {
            private$tasks$worker[[i]]$call(
              api_function,
              private$tasks$args[[i]])
          }
        })
      }
    )
  )

  return(task_q)
}
