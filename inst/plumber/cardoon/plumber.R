api_version <- "0.2.0"
# this need to be in the first line, since it is updated automatically
# via `misc/update_DESCRIPTION_NEWS.R`


# create default function if it does not exit for local development and testing
# the api_function is used from the parent environment in run_cardoon()

library(caRdoon)

if (!exists("api_function")) {
  api_function <- function(id = 1, ...) {
    sleep <- runif(1) * 10 + id
    Sys.sleep(sleep)
    return(sleep)
  }
}


# loads the port from the global env, which was set within run_cardoon()
api_port <- Sys.getenv("CARDOON_PORT", "8000")
api_path <- paste0("http://127.0.0.1:", api_port)

# get number of worker
num_worker <- as.integer(Sys.getenv("CARDOON_NUM_WORKER", "1"))
# get values for background process
check_seconds <- as.integer(Sys.getenv("CARDOON_CHECK_SECONDS", "60"))
sleep_time <- as.integer(Sys.getenv("CARDOON_SLEEP_TIME", "10"))
log_path <- Sys.getenv("CARDOON_LOG_PATH", "logs/")
db_name <- Sys.getenv("CARDOON_DB_NAME", "caRdoon_task.sqlite")
db_init <- as.logical(Sys.getenv("CARDOON_DB_INIT", "FALSE"))

logger::log_info("loaded env vars:\n",
                 "API path         : ", api_path, "\n",
                 "docs path        : ", api_path, "/__docs__/\n",
                 "logs path        : ", log_path, "\n",
                 "number of workers: ", num_worker, "\n",
                 "checking seconds : ", check_seconds, "\n",
                 "sleeping time    : ", sleep_time, "\n")


# Task queue --------------------------------------------------------------

logger::log_info("setup R6 object")
task_q <- caRdoon:::create_task_object(
  num_worker = num_worker,
  db_init = db_init,
  db_name = db_name,
  api_function = api_function)
q <- task_q$new()


# background process ------------------------------------------------------

bg_log_file <- paste0("bg_log_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
bg_log_path <- file.path(log_path, bg_log_file)
if (!dir.exists(dirname(bg_log_path))) {
  logger::log_info("create logging folder: '", dirname(bg_log_path), "'")
  dir.create(dirname(bg_log_path), recursive = TRUE)
}

logger::log_info("start background process")
rbg_nextjob <- callr::r_bg(
  # TODO change logging file to parameter
  func = caRdoon:::create_background_process,
  args = list(api_path = api_path,
              check_seconds = check_seconds,
              sleep_time = sleep_time),
  stdout = bg_log_path,
  stderr = bg_log_path
)

# create_background_process(api_path = api_path,
#             check_seconds = 5,
#             sleep_time = 1,
#             log_path = log_path)

logger::log_info("caRdoon API ready")

# endpoints ---------------------------------------------------------------

#* Echo the parameter that was sent in
#* param num:int number of task to be checked
#* @get /nextJob
function() {
  task_result <- q$pop(0)
  if (!is.null(task_result)) {
    logger::log_info(task_result$task_id,
                     " done with status ",
                     task_result$code)
    if (!is.null(task_result$error)) {
      logger::log_error(task_result$error)
    }

  }
}

# test function and data
# foo <- function(
    #     id = 1,
#     msg = "done",
#     log_path = "") {
#
#   Sys.sleep(runif(1)*10)
#   out_file <- paste0(log_path, "logs_",
#                      gsub(":", "", Sys.time()), "_id_", id)
#   writeLines(text = paste(id, msg), con = out_file)
#
# }
# example_data <- jsonlite::toJSON(list(
#   #"id" = c("aa", "bb", "cc"),
#   "func" = foo,
#   "args_list" = list(
#     "id" =  1,
#     "msg" = paste0(rep(LETTERS[i], i), collapse = ""),
#     "log_path" = "/Users/jakobgepp/Projekte/Intern/caRdoon/"
#   )
# ))

#* Add a new job to the list
#* @param data:object an object with args_list that contains all
#*  needed parameters for the used api function
#* @post /addJob
function(req) {

  data <- req$argsBody

  q$push(args = data$args_list)
  print("done addJob")

}


#* List task queue
#* @get /tasklist
function() {
  tmp_list <- q$list_tasks()
  print(tmp_list)
  return(tmp_list[c("id", "idle", "state")])
}


#* Add a new job to the list
#* @param id:numeric a numeric ID of a task
#* @post /getResult
function(req, res) {
  this_id <- as.integer(req$args$id)

  tmp_list <- q$list_tasks()
  all_ids <- tmp_list$id
  out <- NULL

  # TODO add check in DB for result too
  if (!this_id %in% all_ids) {
    msg <- paste0("no task found with this id: '", this_id, "'")
    logger::log_info(msg)
    res$status <- 404 # Not found
    out <- list(error = msg)
  }


  if (this_id %in% all_ids) {

    # only finished task can be returned
    this_row <- match(this_id, all_ids)
    this_state <- tmp_list$state[this_row]
    is_idle <- tmp_list$idle[this_row]

    if (this_state %in% c("done")) {
      #browser()
      out <- tmp_list$result[this_row][[1]]$result
    }

    # only non-idle task can have a result
    # idle task return NULL
    if (!is_idle && !(this_state %in% c("done"))) {
      msg <- paste0("job with id ", this_id, " (", this_state, ")",
                    " is not 'done' yet")
      logger::log_info(msg)
      res$status <- 404 # Not found
      out <- list(error = msg)
    }
  }

  return(out)
}


#* Returns true if running and available
#* @get /ping
function() {
  return(TRUE)
}


#* Returns version
#* @get /version
function() {
  cat("Version:", api_version, "\n")
  return(api_version)
}

#* Returns status of background process
#* @get /background
function() {
  print(rbg_nextjob)
  return(rbg_nextjob$format())
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
