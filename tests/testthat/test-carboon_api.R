testthat::context("API testing")


testthat::test_that("local deployment works", {

  # TODO figure out how to test API setup
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
