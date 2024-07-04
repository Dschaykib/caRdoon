# :leafy_green: caRdoon - 0.2.0 <img src="misc/cardoon.png" width=170 align="right" />

A task queue API for R roughly based on functionality of [celery](https://github.com/celery/celery).

> "Cardoon leaf stalks, which look like giant celery stalks ..."

Source: [Wikipedia](https://en.wikipedia.org/wiki/Cardoon)

# Disclaimer

This is still work in progress and functionality or parameters might change.

# Installation

``` R
# with renv from GitHub
renv::install("Dschaykib/caRdoon")
library(caRdoon)
```

# Motivation

I have build quite a few R Shiny apps and most of them had some kind of API connection to run a model in the background (e.g. for some forcasting). If the model takes a while to compute, one questions arises: "What does the user do in the meantime?"

Most important, the app should not be blocked. So if the user wants to do some other tasks or checks in the app, they should be able to. You could use [promises with the future package](https://rstudio.github.io/promises/articles/promises_06_shiny.html) or use R background processes. Both of these are valid solutions, but I also had the additional 'requirement' that the user wants to know the status of their long running task.

To solve this, I took inspiration from [celery](https://github.com/celery/celery) and [this blog post](https://www.tidyverse.org/blog/2019/09/callr-task-q/) to create caRdoon – a task queue API for R.


# TLDR

You need to provide a function to the API during startup. This function is now called and executed for each task you add with `/addJob` and the given parameters.
You can get an overview of all task by calling `/tasklist` and receive each functions result with `/getResult`.



# Background Setup

The background setup looks like this:
<img src="misc/target-setup.png" align="center" />


# Usage

The package provides the setup described above. To start the local API use the function `run_cardoon()` and set the `api_function`. Check out `help(run_cardoon, "caRdoon")` for more details.

```
library(caRdoon)

# simple test function
api_function <- function(id = 1) {
  sleep <- runif(1) * 10 + id
  Sys.sleep(sleep)
  return(sleep)
}

run_cardoon(port = 8000, api_function = api_function)
```

Access the API's endpoints from an other R process or start the code above in an R terminal.

The main endpoints are:

#### /addJob

This will add a new job to the task list. The added job contains all parameter needed for the current api function in `args_list`. Since the process is spawned in a separate R process in the background, it does not have access to the global environment. The results of each function are stored in a database.

For example:

``` R

library(jsonlite)
library(httr)

# set parameters for simple test function
this_body <- jsonlite::toJSON(list(
  "args_list" = list(
    "id" =  2
  )
))

httr::POST(url = "http://127.0.0.1:8000/addJob",
           body = this_body)

```

#### /tasklist

This will return a table with the current jobs and their status.


``` R

library(httr)
api_tasklist <- httr::GET(url = "http://127.0.0.1:8000/tasklist")

# combine the output list into a data.frame
as.data.frame(do.call(rbind, httr::content(api_tasklist)))

```

Here is an example output with one worker node (id = -1) and three tasks. One is done, one is currently running and one is still waiting.

```
  id  idle   state
1  1 FALSE    done
2  2 FALSE running
3  3 FALSE waiting
4 -1  TRUE waiting
```


#### /getResult

This endpoint returns the function's output if it finished successfully. To get specific results the internal `id` is used, which can be received via the `/tasklist` endpoint.

```
this_body <- jsonlite::toJSON(list("id" =  1))

res_1 <- httr::POST(url = "http://127.0.0.1:8000/getResult",
                    body = this_body)

httr::content(res_1)
```

In the simple test function, the random sleeping time is returned:

```
[[1]]
[1] 7.8385
```

# Ideas and TODOs

First a small working package is planed, but there are already ideas floating around for improvements and enhancements. For example:

- [x] integrate testing
- [x] add logging within API
- [ ] check error handling, errors within the worker (memory, exceptions, ...)
- [ ] remove dependencies
- [x] adding a file/DB to store results
- [ ] provide docker container
- [ ] add priority for tasks
- [ ] add comments in code
- [ ] update README with example output
- [ ] check if global variables are needed or can be replaced by inputs
- [ ] add status to API enpoints
- [x] refactor so that used function is given at startup time not during run time per API call
- [ ] ...


# Notes

Source image for the hex-icon from [Flaticon](https://www.flaticon.com/free-icons/celery).

