api_version <- "0.0.0.9002"
# this need to be in the first line, since it is updated automatically

API_PATH <- "http://127.0.0.1:9662"


# background process ------------------------------------------------------

rp1 <- callr::r_bg(
  func = function(api_path) {
    # setup time to initialize API
    Sys.sleep(2)
    # setup to check if API is still running
    check_api <- function() {
      tryCatch({
        httr::GET(paste0(api_path, "/ping"))
      },
      error = function(e) FALSE)
    }
    is_alive <- TRUE
    start_time <- Sys.time()
    # seconds between is_alive checks
    check_seconds <- 60
    # seconds between API calls
    sleep_time <- 10


    # loop for constant checks, to keep process updating
    while(is_alive) {
      Sys.sleep(sleep_time)
      check <- tryCatch({httr::GET(paste0(api_path, "/nextJob"))},
                        error = function(e){})

      # update is_alive every x seconds
      time_diff <- floor(as.numeric(difftime(
        Sys.time(), start_time, units = "secs")
      ))
      if (time_diff %% check_seconds == 0) {
        is_alive <- check_api()
        print(paste0("check if API is alive:", is_alive))
      }

    }
  },
  args = list(api_path = API_PATH))

# Task queue --------------------------------------------------------------


task_q <- R6::R6Class(
  "task_q",
  public = list(
    initialize = function(concurrency = 1L) {
      private$start_workers(concurrency)
      invisible(self)
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
      private$tasks <- tibble::add_row(private$tasks, .before = before,
                                       id = id, idle = FALSE, state = "waiting", fun = list(fun),
                                       args = list(args), worker = list(NULL), result = list(NULL))
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
    next_id = 1L,
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
        private$tasks <- tibble::add_row(private$tasks,
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

q <- task_q$new()

# endpoints ---------------------------------------------------------------


#* Echo the parameter that was sent in
#* param num:int number of task to be checked
#* @get /nextJob
function(){
  task_result <- q$pop(0)
}



#* Add a new job to the list
#* @param data:object
#* @post /addJob
function(req) {
  # cat("addJob:", ids, "\n")

  data <- req$argsBody
  func <- eval(parse(text = data$func))

  q$push(fun = func, args = data$args_list)

  print("done addJob")

}


#* List task queue
#* @get /tasklist
function(){
  tmp_list <- q$list_tasks()
  print(tmp_list)
  return(tmp_list[c("id", "idle", "state")])
}

#* Return version
#* @get /version
function(){
  cat("Version:", api_version, "\n")
  return(api_version)
}

#* Returns true if running and available
#* @get /ping
function(){
  return(TRUE)
}


# update API documentation
#* @plumber
function(pr) {
  oas <- function(spec) {
    spec$info$version <- api_version
    spec$info$title <- "caRdoon API"
    spec$info$description <- "An API to create a task queue in R."
    spec
  }
  pr$setApiSpec(oas)
}
