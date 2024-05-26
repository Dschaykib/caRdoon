# a collection of helper functions to read and write tasks data
# initially this is done with a csv file
# but could be upgraded to a database

# TODO write complete task table
# TODO read complete task table
# TODO add a new row


# TODO update an existing row by key
#' Add quotations on string values
#' @param x an object of length one, either a numeric or a character
#' @return a string
get_value <- function(x) {
  #x <- set[[1]]
  x_class <- class(x)
  if (x_class == "character") {
    out <- paste0("'", x, "'")
  } else if (x_class %in% c("numeric", "integer")) {
    out <- x
  } else {
    stop("x should be either a character or a numeric")
  }
  return(out)
}
#' Extracts values from list for SQL statement
#' @param x named list, where the name is the column and the value the value
#' @return a string with name-value pairs separated by commas.
#'
get_sql_value <- function(x) {
  x_values <- lapply(X = x, FUN = get_value)

  out <- paste0(
    paste0(names(x), "=", unlist(x_values)),
    collapse = ",")

  return(out)
}

#' Send UPDATE SQL statement
#' @param con connection to database
#' @param tablename name of the table in DB
#' @param key a named list with key parameters, where the name is the column and
#'   the value the value. Used in WHERE SQL-statement.
#' @param set a named list with update parameters, where the name is the column
#'   and the value the value. Used in SET SQL-statement.
#'
#' @return a Boolean that indicates if the SQL statement was successful.
#'
db_update_row <- function(con, tablename, key, set) {

  # con <- cardoon_db
  # tablename <- "tasks"
  # set and key are named vectors
  # set <- list(state = "waiting", idle = 2)
  # key <- list(id = 1)

  upd_sql <- paste0(
    "UPDATE ", tablename,
    " SET ", get_sql_value(set),
    " WHERE ", get_sql_value(key)
  )

  check <- tryCatch({
    DBI::dbSendQuery(con, upd_sql)
  }, error = function(e) e
  )

  out <- !any(c("error", "simpleError") %in% class(check))

  # task_db3 <- DBI::dbReadTable(cardoon_db, "tasks")
  # task_db3[,c("id", "state", "result")]

  return(out)

}
