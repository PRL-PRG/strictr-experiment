#!/usr/bin/env Rscript

options(error = function() { traceback(3); q(status=1) })

library(glue)
library(readr)
library(runr)

wrap <- function(package, file, type, body) {
    glue(
        "library(strictr)",
        "data <- trace_strictness(",
        "code = {{",
        "    {BODY}",
        "}},",
        "quote = TRUE)",
        "dirpath <- file.path(Sys.getenv('RUNR_CWD'), '{TYPE}', basename('{FILE}'))",
        "dir.create(dirpath, recursive=TRUE, showWarnings=FALSE)",
        "write_tracing_data(data, dirpath = dirpath)",
        .sep = "\n",
        FILE = file,
        TYPE = type,
        BODY = gsub('\n', '\n      ', body)
    )
}

wrap_files <- Vectorize(function(package, file, type) {
    dir <- dirname(file)

    if (type == "tests" &&
        (endsWith(tolower(file), "tests/testthat.r") ||
         endsWith(tolower(file), "tests/run-all.r") ||
         endsWith(tolower(file), "tests/test-all.r")) &&
        dir.exists(file.path(dir, "testthat"))) {
        tt_dir <- file.path(dir, "testthat")
        tt_helpers <- list.files(tt_dir, pattern="helper.*\\.[rR]$", full.names=T, recursive=T)
        tt_tests <- list.files(tt_dir, pattern="test.*\\.[rR]$", full.names=T, recursive=T)
        tt_files <- c(tt_helpers, tt_tests)

        wrap_files(package, tt_files, rep("tests", length(tt_files)))
    } else {
        message("- updating ", file, " (", type, ")")

        body <- read_file(file)
        new_body <- wrap(package, file, type, body)
        tryCatch({
            parse(text=new_body)
        }, error=function(e) {
            message("E unable to parse wrapped file", file, ": ", e$message)
        })
        write_file(new_body, file)
    }
}, vectorize.args=c("file", "type"))

script <- system.file(
    "tasks/package-runnable-code.R",
    package="runr",
    mustWork=T
)

env <- new.env()

sys.source(script, envir=env)

df <- env$df

invisible(wrap_files(env$package, df$path, df$type))
