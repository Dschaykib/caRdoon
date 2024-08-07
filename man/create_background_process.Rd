% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_background_process.R
\name{create_background_process}
\alias{create_background_process}
\title{Function to periodically call the API's endpoint to keep the queue moving}
\usage{
create_background_process(
  api_path,
  check_seconds = 60,
  sleep_time = 10,
  retry = 5
)
}
\arguments{
\item{api_path}{string with the path to the API.}

\item{check_seconds}{integer with number of seconds before the background
process checks if the API is still alive. See Details.}

\item{sleep_time}{integer with the number of seconds the background process
sleeps before triggering the API's queue again.}

\item{retry}{number of consecutive failed retries before the process is
terminated.}
}
\value{
no actual return value
}
\description{
Function to periodically call the API's endpoint to keep the queue moving
}
\details{
When the API is not alive anymore, this process is terminated after
  a number of retries.
}
