create_db_row <- function(data) {

  # data <- new_row
  # data has only 1 row
  # "list" columns are transformed

  data_db <- lapply(
    X = data,
    FUN = function(col) {
      if (inherits(col, what = "list")) {
        out <- rawToChar(serialize(col, ascii = TRUE, connection = NULL))
      } else {
        out <- col
      }
      return(out)
    }
  )

  return(as.data.frame(data_db))
}
