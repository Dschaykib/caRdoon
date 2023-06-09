testthat::context("API testing")


testthat::test_that("local deployment works", {

  logger::log_info("start API in background")
  rs <- callr::r_bg(
    function() {
      caRdoon::run_cardoon(port = 8000)
    }, package = "caRdoon")
  print(rs)
  print(rs$read_output())
  # wait for API to start
  Sys.sleep(1)

  logger::log_info("API ping call")
  link <- "http://localhost:8000/ping"
  call <- tryCatch(
    httr::GET(url = link),
    error = function(x) NA)
  #,
  # httr::add_headers(
  #   `accept` = 'application/json'),
  # httr::content_type("application/json")

  print(rs$read_output())
  print(call)

  call_parse <- tryCatch(
    httr::content(call, encoding = "UTF-8"),
    error = function(x) NA)

  print(call_parse)

  testthat::expect_equal(unlist(call_parse), TRUE)

  rs$kill()

})

testthat::test_that("enpoints have correct format", {

  # this test is done to ensure or at least check for backwards compabilitiy

  logger::log_info("start API in background")
  rs <- callr::r_bg(
    function() {
      caRdoon::run_cardoon(port = 8000)
    }, package = "caRdoon")
  print(rs)
  print(rs$read_output())
  # wait for API to start
  Sys.sleep(1)


  # /ping
  logger::log_info("test /ping")
  link <- "http://localhost:8000/ping"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "logical")


  # /version
  logger::log_info("test /version ")
  link <- "http://localhost:8000/version"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "character")


  # /background
  logger::log_info("test /background ")
  link <- "http://localhost:8000/background"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "character")


  # /tasklist
  logger::log_info("test /tasklist ")
  link <- "http://localhost:8000/tasklist"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "list")
  testthat::expect_named(call[[1]], c("id", "idle", "state"))


  # /nextJob
  logger::log_info("test /nextJob ")
  link <- "http://localhost:8000/nextJob"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  # returns empty list, since no jobs are waiting
  testthat::expect_type(call, "list")

  # /addJob has no return value

  rs$kill()

})

testthat::test_that("example function works", {

  logger::log_info("start API in background")
  rs <- callr::r_bg(
    function() {
      caRdoon::run_cardoon(port = 8000)
    }, package = "caRdoon")
  print(rs)
  print(rs$read_output())
  # wait for API to start
  Sys.sleep(1)

  # the default number of workers is 1
  logger::log_info("API get tasks before adding jobs")
  link <- "http://localhost:8000/tasklist"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)

  call_dt <- Reduce(rbind, lapply(call, as.data.frame))
  testthat::expect_equal(nrow(call_dt), 1)


  # adding jobs
  foo <- function(id = 1, msg = "done") {
    Sys.sleep(runif(1))
    print(msg)
    }

  i <- 1
  test_runs <- 5
  for (i in seq(test_runs)) {
    this_body <- jsonlite::toJSON(list(
      "func" = foo,
      "args_list" = list("id" =  i, "msg" = i
      )
    ))

    httr::POST(url = "http://127.0.0.1:8000/addJob", body = this_body)
  }



  logger::log_info("API get tasks after adding jobs")
  link <- "http://localhost:8000/tasklist"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)

  call_dt <- Reduce(rbind, lapply(call, as.data.frame))

  # the default number of workers is 1, therefore +1 idle job
  testthat::expect_equal(nrow(call_dt), test_runs + 1)


  rs$kill()

})

