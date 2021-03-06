setwd(rstudioapi::getActiveProject())
curr <- getwd()
pkg <- basename(curr)

rv <- R.Version()
rv <- paste0(rv$major, ".", strsplit(rv$minor, ".", fixed = TRUE)[[1]][1])

rvprompt <- readline(prompt = paste0("Running for R version: ", rv, ". Is that what you wanted y/n: "))
if (grepl("[nN]", rvprompt)) stop("Change R-version")

dirsrc <- "../minicran/src/contrib"

if (rv == "3.3") {
  dirmac <- fs::path("../minicran/bin/macosx/mavericks/contrib", rv)
} else {
  dirmac <- fs::path("../minicran/bin/macosx/el-capitan/contrib", rv)
}

dirwin <- fs::path("../minicran/bin/windows/contrib", rv)

if (!fs::file_exists(dirsrc)) fs::dir_create(dirsrc, recursive = TRUE)
if (!fs::file_exists(dirmac)) fs::dir_create(dirmac, recursive = TRUE)
if (!fs::file_exists(dirwin)) fs::dir_create(dirwin, recursive = TRUE)

## delete older version of radiant
rem_old <- function(app) {
  unlink(paste0(dirsrc, "/", app, "*"))
  unlink(paste0(dirmac, "/", app, "*"))
  unlink(paste0(dirwin, "/", app, "*"))
}

sapply(pkg, rem_old)

## avoid 'loaded namespace' stuff when building for mac
system(paste0(Sys.which("R"), " -e \"setwd('", getwd(), "'); app <- '", pkg, "'; source('build/build_mac.R')\""))

win <- readline(prompt = "Did you build on Windows? y/n: ")
if (grepl("[yY]", win)) {

  ## move packages to radiant_miniCRAN. must package in Windows first
  pth <- fs::path_abs("../")

  sapply(list.files(pth, pattern = "*.tar.gz", full.names = TRUE), file.copy, dirsrc)
  unlink("../*.tar.gz")
  sapply(list.files(pth, pattern = "*.tgz", full.names = TRUE), file.copy, dirmac)
  unlink("../*.tgz")
  sapply(list.files(pth, pattern = "*.zip", full.names = TRUE), file.copy, dirwin)
  unlink("../*.zip")

  tools::write_PACKAGES(dirmac, type = "mac.binary")
  tools::write_PACKAGES(dirwin, type = "win.binary")
  tools::write_PACKAGES(dirsrc, type = "source")

  # commit to repo
  setwd("../minicran")
  system("git add --all .")
  mess <- paste0(pkg, " package update: ", format(Sys.Date(), format = "%m-%d-%Y"))
  system(paste0("git commit -m '", mess, "'"))
  system("git push")
}

setwd(curr)
