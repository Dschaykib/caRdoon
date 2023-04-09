foo <- function(
    id = 1,
    msg = "done",
    log_path = "") {

  Sys.sleep(runif(1)*10)
  out_file <- paste0(log_path, "logs_",
                     gsub(":", "", Sys.time()), "_id_", id)
  writeLines(text = paste(id, msg), con = out_file)

}


i <- 111

for (i in 1:10) {

  this_body <- jsonlite::toJSON(list(
    #"id" = c("aa", "bb", "cc"),
    "func" = foo,
    "args_list" = list(
      "id" =  i,
      "msg" = paste0(rep(LETTERS[i], i), collapse = ""),
      "log_path" = "/Users/jakobgepp/Projekte/Intern/caRdoon/"
    )
  ))

  httr::POST(url = "http://127.0.0.1:8000/addJob",
             body = this_body)

}

#aa <- httr::GET(url = "http://127.0.0.1:9662/tasklist")
#data.table::rbindlist(httr::content(aa))



  q$push(fun = foo, args = list(
    "id" =  i,
    "msg" = paste0(rep(LETTERS[i], i), collapse = ""),
    "log_path" = "/Users/jakobgepp/Projekte/Intern/caRdoon/"
  ))
