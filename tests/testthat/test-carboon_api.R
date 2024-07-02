
testthat::test_that("local deployment works", {

  # so that it is available for all tests

  # logger::log_info("API ping call")
  link <- "http://localhost:8000/ping"
  call <- tryCatch(
    httr::GET(url = link),
    error = function(x) NA)
  #,
  # httr::add_headers(
  #   `accept` = 'application/json'),
  # httr::content_type("application/json")

  call_parse <- tryCatch(
    httr::content(call, encoding = "UTF-8"),
    error = function(x) NA
  )

  print(call_parse)

  testthat::expect_equal(unlist(call_parse), TRUE)

})

testthat::test_that("enpoint ping has correct format", {

  # this test is done to ensure or at least check for backwards compabilitiy

  # /ping
  # logger::log_info("test /ping")
  link <- "http://localhost:8000/ping"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "logical")

})

testthat::test_that("enpoint version has correct format", {

  # /version
  # logger::log_info("test /version ")
  link <- "http://localhost:8000/version"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "character")

})
testthat::test_that("enpoint background has correct format", {

  # /background
  # logger::log_info("test /background ")
  link <- "http://localhost:8000/background"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "character")

})
testthat::test_that("enpoint tasklist has correct format", {


  # /tasklist
  # logger::log_info("test /tasklist ")
  link <- "http://localhost:8000/tasklist"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  testthat::expect_type(call[[1]], "list")
  testthat::expect_named(call[[1]], c("id", "idle", "state"))

})


testthat::test_that("enpoint nextJob has correct format", {


  # /nextJob
  # logger::log_info("test /nextJob ")
  link <- "http://localhost:8000/nextJob"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)
  # returns empty list, since no jobs are waiting
  testthat::expect_type(call, "list")

  # /addJob has no return value
})


testthat::test_that("example function works", {

  # the default number of workers is 1
  # logger::log_info("API get tasks before adding jobs")
  link <- "http://localhost:8000/tasklist"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)

  call_dt <- Reduce(rbind, lapply(call, as.data.frame))
  testthat::expect_equal(nrow(call_dt), 1)


  # adding jobs
  foo <- function(id = 1, msg = "done") {
    Sys.sleep(2 + runif(1))
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



  # logger::log_info("API get tasks after adding jobs")
  link <- "http://localhost:8000/tasklist"
  call <- tryCatch(
    httr::content(httr::GET(url = link), encoding = "UTF-8"),
    error = function(x) NA)

  call_dt <- Reduce(rbind, lapply(call, as.data.frame))

  # the default number of workers is 1, therefore +1 idle job
  testthat::expect_equal(nrow(call_dt), test_runs + 1)


})


testthat::test_that("enpoint getResult is an empty list for idle tasks", {

  # /getResult
  link <- "http://localhost:8000/getResult"
  # idle task have negative ids
  this_body <- jsonlite::toJSON(list("id" = -1L))

  api_content <- tryCatch(
    expr = {
      api_call <- httr::POST(url = link, body = this_body)
      httr::content(api_call, encoding = "UTF-8")
    },
    error = function(x) NA
  )

  # returns list() because idle task is never done
  print(api_content)
  testthat::expect_type(api_content, "list")
  testthat::expect_length(api_content, 0)

})


testthat::test_that("enpoint getResult is working", {

  # /getResult
  link <- "http://localhost:8000/getResult"
  # idle task have negative ids
  this_body <- jsonlite::toJSON(list("id" = -1L))

  api_content <- tryCatch(
    expr = {
      api_call <- httr::POST(url = link, body = this_body)
      httr::content(api_call, encoding = "UTF-8")
    },
    error = function(x) NA
  )

  # returns list() because idle task is never done
  testthat::expect_type(api_content, "list")
  testthat::expect_length(api_content, 0)

})
