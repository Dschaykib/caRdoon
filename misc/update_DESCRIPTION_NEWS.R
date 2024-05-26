# script to create the DESCRIPTION file

# Remove default DESC and NEWS.md
unlink("DESCRIPTION")
unlink("NEWS.md")

# initial files -----------------------------------------------------------

# Create a new description object
my_desc <- desc::description$new("!new")
my_news <- newsmd::newsmd()

# Set your package name
my_desc$set("Package", "caRdoon")
# Set license
my_desc$set("License", "MIT + file LICENSE")

# Remove some author fields
my_desc$del("Maintainer")
# Set the version
my_desc$set_version("0.0.0.9000")
# The title of your package
my_desc$set(Title = "A task queue API for R")
# The description of your package
my_desc$set(Description =
  paste0("Contains an API to create a task queue overview."))
# The urls
my_desc$set("URL", "https://github.com/Dschaykib/caRdoon")
my_desc$set("BugReports",
            "https://github.com/Dschaykib/caRdoon/issues")

#Set authors
my_desc$set("Authors@R",
            paste0("person('Jakob', 'Gepp',",
                   "email = 'jakob.gepp@yahoo.de',",
                   "role = c('cre', 'aut'))"))

# set R version
#my_desc$set_dep("R", type = desc::dep_types[2])

# set suggests
my_desc$set_dep("testthat", type = desc::dep_types[3], version = "*")
my_desc$set_dep("origin", type = desc::dep_types[3], version = "*")
my_desc$set_dep("newsmd", type = desc::dep_types[3], version = "*")

# set dependencies
my_desc$set_dep("R6", type = desc::dep_types[1])
my_desc$set_dep("plumber", type = desc::dep_types[1])
my_desc$set_dep("callr", type = desc::dep_types[1])
my_desc$set_dep("httr", type = desc::dep_types[1])

# set staging setting
#my_desc$set("StagedInstall", "no")



# initial functions -------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_news$add_bullet(c("add API code "))


# fix testing -------------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_news$add_bullet(c("fix testing setup",
                     "update documentation"))

# change port and worker handling -----------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_news$add_bullet(c("fix testing setup",
                     "update documentation"))

# add env settings --------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_news$add_bullet(c("add env vars sleep_time and check_seconds"))

# refactor and fixes ------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_desc$set_dep("logger", type = desc::dep_types[1])
my_desc$set_dep("tibble", type = desc::dep_types[1])
my_desc$set_dep("processx", type = desc::dep_types[1])

my_news$add_bullet(c("refactor internal functions",
                     "add logging",
                     "fix tests"))


# refactor and fixes ------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_desc$set_dep("jsonlite", type = desc::dep_types[3], version = "*")

my_news$add_bullet(c("update tests and logging",
                     "fix typos"))

# bump to minor version ---------------------------------------------------

my_desc$bump_version("patch")
my_news$add_version(my_desc$get_version())


# minor docu fixes --------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())

my_news$add_bullet(c("update documentation",
                     "fix bug with number of workers",
                     "fix typos"))

# add database for storage ------------------------------------------------

my_desc$bump_version("minor")
my_news$add_version(my_desc$get_version())

my_news$add_bullet(c("add RSQLite database to store queue and results",
                     "refactor background process"))

my_desc$set_dep("DBI", type = desc::dep_types[1])
my_desc$set_dep("RSQLite", type = desc::dep_types[1])


# fix DB setup --------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())
my_desc$set_dep("lintr", type = desc::dep_types[3])
my_desc$set_dep("withr", type = desc::dep_types[3])

my_news$add_bullet(c("refactor DB setup and tests",
                     "add lintr and withr"))

# fix DB setup --------------------------------------------------------

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())
my_news$add_bullet(c("adjust logging"))

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())
my_news$add_bullet(c("fix id type to numeric"))

my_desc$bump_version("dev")
my_news$add_version(my_desc$get_version())
my_news$add_bullet(c("add DB updates for status",
                     "update .lintr options"))

# WIP ---------------------------------------------------------------------

# bump dev version
#my_desc$bump_version("dev")
#my_news$add_version(my_desc$get_version())
#my_news$add_bullet(c("current dev version"))


# save everything ---------------------------------------------------------

my_desc$set("Date", Sys.Date())
my_desc$write(file = "DESCRIPTION")
my_news$write(file = "NEWS.md", reduce_dev = TRUE)

# set API version
cardoon_api_file <- readLines("inst/plumber/cardoon/plumber.R")
cardoon_api_file[1] <- paste0(
  'api_version <- "', my_desc$get_version(), '"')
writeLines(cardoon_api_file, "inst/plumber/cardoon/plumber.R")

# set CRAN version number in README
my_readme <- readLines("README.md")
my_readme[1] <- paste0(
  "# :leafy_green: caRdoon - ", my_desc$get_version(),
  " <img src=\"misc/cardoon.png\" width=170 align=\"right\" />")


# set dev version number
# my_readme <- gsub(pattern = "badge/Version-.*-success",
#                   replacement = paste0("badge/Version-",
#                                        my_desc$get_version(),
#                                        "-success"),
#                   x = my_readme)

writeLines(my_readme, "README.md")


# pkg builds and checks ---------------------------------------------------

# update renv packages if needed
renv::clean()
renv::snapshot(prompt = TRUE, exclude = "caRdoon")

# set pkg names
origin::originize_pkg()

# check lints
lintr::lint_package()

# update documentation
roxygen2::roxygenise()
# tidy DESCRIPTON
usethis::use_tidy_description()

# clean and install package!
utils::menu(
  choices = c("Yes", "No"),
  title = "Did you press 'clean and install' yet?"
)

# check package structure
devtools::check(document = FALSE)
