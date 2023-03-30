

library(httr)


httr::GET("http://127.0.0.1:5762/slowcalc?msg=langsam")
httr::GET("http://127.0.0.1:5762/test?msg=schnell")

httr::GET("http://127.0.0.1:5762/echo?msg=kmadgs", httr::timeout(2))

httr::GET("http://127.0.0.1:5762/echo?msg=kmadgs", httr::timeout(20))




## loop
for (i in 1:100) {
  Sys.sleep(0.1)
  httr::GET("http://127.0.0.1:5762/nextJob")
}


httr::GET("http://127.0.0.1:5762/version")


httr::GET("http://127.0.0.1:5762/tasklist")

httr::GET("http://127.0.0.1:5762/tasklist")

system(command = 'curl -X POST "http://127.0.0.1:5762/addJob?offers=1&offers=2&offers=3&offers=4" -H "accept: */*" -d ""')

# body test

this_body <- jsonlite::toJSON(list(
  "aa" = 1,
  "bb" = list (a = 1:4, b = 5:7),
  "cc" = "skgsk"
))

httr::POST(url = "http://127.0.0.1:5762/bodytest",
           body = this_body)
