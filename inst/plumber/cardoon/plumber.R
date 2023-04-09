api_version <- "0.0.0.9006"
# this need to be in the first line, since it is updated automatically

# loads the port from the global env, which was set within run_cardoon()
api_port <- Sys.getenv("CARDOON_PORT", "8000")
api_path <- paste0("http://127.0.0.1:", api_port)

# get number of worker
num_worker <- as.integer(Sys.getenv("CARDOON_NUM_WORKER", "1"))
# get values for background process
check_seconds <- as.integer(Sys.getenv("CARDOON_CHECK_SECONDS", "60"))
sleep_time <- as.integer(Sys.getenv("CARDOON_SLEEP_TIME", "10"))

logger::log_info("loaded env vars:\n",
                 "API path         : ", api_path, "\n",
                 "number of workers: ",num_worker, "\n",
                 "checking seconds : ",check_seconds, "\n",
                 "sleeping time    : ",sleep_time, "\n")

# background process ------------------------------------------------------

# TODO remove into helper script?
logger::log_info("start background process")
rbg_nextjob <- callr::r_bg(
  # TODO change logging file to parameter
  func = function(api_path, check_seconds = 60, sleep_time = 10) {

    print("initialise caRdoon background process")
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
    # check_seconds <- 60
    # seconds between API calls
    # sleep_time <- 10


    # loop for constant checks, to keep process updating
    print("start caRdoon background process loop")
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
    print("end caRdoon background process loop")
  },
  args = list(api_path = api_path,
              check_seconds = check_seconds,
              sleep_time = sleep_time)
  )

# Task queue --------------------------------------------------------------

logger::log_info("setup R6 object")
task_q <- caRdoon:::create_task_object()
q <- task_q$new()

logger::log_info("caRdoon API ready")
# endpoints ---------------------------------------------------------------


#* Echo the parameter that was sent in
#* param num:int number of task to be checked
#* @get /nextJob
function(){
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


#* Add a new job to the list
#* @param data:object
#* @post /addJob
function(req) {
  # cat("addJob:", ids, "\n")

  data <- req$argsBody
  func <- eval(parse(text = data$func))

  if (is.null(func)) {
    print("no function found in $func")
  } else {
    q$push(fun = func, args = data$args_list)
    print("done addJob")
  }
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


#* Returns version
#* @get /version
function(){
  cat("Version:", api_version, "\n")
  return(api_version)
}

#* Returns status of background process
#* @get /background
function(){
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
