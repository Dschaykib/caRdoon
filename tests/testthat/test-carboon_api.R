testthat::context("API testing")


testthat::test_that("local deployment works", {

  # TODO figure out how to test API setup
  rs <- callr::r_bg(
    function() {
      run_cardoon(port = 9662)
    }, package = "caRdoon")

  # wait for API to start
  Sys.sleep(3)

  link <- "http://localhost:9662/ping"

  call <- tryCatch(
    httr::GET(
      url = link,
      httr::add_headers(
        `accept` = 'application/json'),
      httr::content_type("application/json")
    ),
    error = function(x) NA)

  print(call)

  call_parse <- tryCatch(
    httr::content(call, encoding = "UTF-8"),
    error = function(x) NA)

  print(call_parse)

  testthat::expect_equal(unlist(call_parse), TRUE)

  rs$kill()

})
