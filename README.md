# :leafy_green: caRdoon - 0.0.0.9006 <img src="misc/cardoon.png" width=170 align="right" />

A task queue API for R roughly based on functionality of [celery](https://github.com/celery/celery).

> "Cardoon leaf stalks, which look like giant celery stalks ..."

Source: [Wikipedia](https://en.wikipedia.org/wiki/Cardoon)

# Disclaimer

This is still work in progress and functionality, parameters and such might change.

# Installation

``` R
# with renv from GitHub
renv::install("Dschaykib/caRdoon")
library(caRdoon)
```

# Motivation

When building dashboard, calling an model API in the back-end is quite common. If the model takes a while to compute, most users want to know when there task is done or being processed. One solution is a task queue like [celery](https://github.com/celery/celery). Since this is sometime an overkill for small projects, I had the idea to build something similar. I came across this [blog post](https://www.tidyverse.org/blog/2019/09/callr-task-q/) and decided to wrap this all together into a small little package.


# Setup

The target setup looks like this:
<img src="misc/target-setup.png" align="center" />


# Usage

The package provides the setup described above. To start the local API use the function `run_cardoon(port = 8000)` and specify the port, the API should run at.
The main endpoints are:

#### /addJob

This will add a new job to the task list. The added job is a function `func` which needs all parameter given via `args_list`. Since the process is spawned in a separate R process in the background, it does not have access to the global environment.

At the moment, the results are not saved or stored. Therefore, the given function is responsible to save the output or logs.

For example:

``` R
# create a function
foo <- function(id = 1, msg = "done") {
  Sys.sleep(runif(1))
  out_file <- paste0("logs_", gsub(":", "", Sys.time()), "_id_", id)
  writeLines(text = paste(id, msg), con = out_file)
}

this_body <- jsonlite::toJSON(list(
  "func" = foo,
  "args_list" = list(
    "id" =  1,
    "msg" = "finished"
    
  )
))

httr::POST(url = "http://127.0.0.1:8000/addJob",
           body = this_body)

```

#### /tasklist

This will return a table with the current jobs and their status.



# Ideas and TODOs

First a small working package is planed, but there are already ideas floating around for improvements and enhancements. For example:

- [x] integrate testing
- [x] add logging within API
- [ ] check error handling
- [ ] remove dependencies
- [ ] adding a file/DB to store results
- [ ] provide docker container
- [ ] add priority for tasks
- [ ] ...


# Notes

Source image for the hex-icon from [Flaticon](https://www.flaticon.com/free-icons/celery).

