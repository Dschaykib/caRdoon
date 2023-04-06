foo <- function(
    id = 1,
    msg = "done") {
  Sys.sleep(runif(1))
  out_file <- paste0("/Users/jakobgepp/Projekte/2022/BS Energy/App Performance/API-test/Logs/logs_",
                     gsub(":", "", Sys.time()), "_id_", id)
  writeLines(text = paste(id, msg), con = out_file)


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

#aa <- httr::GET(url = "http://127.0.0.1:9662/tasklist")
#data.table::rbindlist(httr::content(aa))
