
testthat::test_that("creating works", {

  tmp <- create_row()

  testthat::expect_type(tmp, "list")
  testthat::expect_equal(nrow(tmp), 1)

  # test naming and order of columns for backwards comparability
  # if test needs to be adjusted bump major version number
  testthat::expect_equal(
    names(tmp),
    c("id", "idle", "state", "fun", "args", "worker", "result"))
  testthat::expect_equal(
    sapply(tmp, class),
    c(id = "integer",
      idle = "logical",
      state = "character",
      fun = "list",
      args = "list",
      worker = "list",
      result = "list"))

})

testthat::test_that("example works", {
  tmp <- create_row(fun = mean, args = list(x = 1:5))

  testthat::expect_type(tmp, "list")
  testthat::expect_equal(nrow(tmp), 1)

  testthat::expect_equal(class(tmp$fun[[1]]), "function")
  testthat::expect_type(tmp$args, "list")
  testthat::expect_type(tmp$args[[1]], "list")


})
