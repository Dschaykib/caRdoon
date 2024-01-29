foo <- function(id = 1, msg = "done") {
  # require(data.table)
  print(1)
  Sys.sleep(i)
  print(head(iris))
  # stop("this is an error")
  dt <- data.table::data.table(x = 1)
  out_file <- paste0("/Users/jakobgepp/Projekte/Intern/caRdoon/logs_",
                     gsub(":", "", Sys.time()), "_id_", id)
  writeLines(text = paste(id, msg), con = out_file)
  return(22)
}

foo(id = 1, msg = "hallo")

i <- 0
i <- i + 1
this_body <- jsonlite::toJSON(list(
  #"id" = c("aa", "bb", "cc"),
  "func" = foo,
  "args_list" = list(
    "id" =  i,
    "msg" = "hallo"

  )
))

httr::POST(url = "http://127.0.0.1:9662/addJob",
           body = this_body)

aa <- httr::GET(url = "http://127.0.0.1:8123/tasklist")
data.table::rbindlist(httr::content(aa))


rs$call(func = foo, args = list(id = 2))
rs$status
rs$read_output()
aa <- rs$read()
rs$get_state()

rs$close()
aa$error
# test r_session run with output ------------------------------------------


