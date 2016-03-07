# funciones para obtener nombres de archivos, a partir de la ruta,
# a diferencia de basename(), estas funciones incluso para los muy largos ###

standardPathFile <- function(x){
  fsep <- .Platform$file.sep
  netshare <- substr(x, 1, 2) == "\\\\"
  if (any(netshare)){
    x[!netshare] <- gsub("\\\\", fsep, x[!netshare])
    y <- x[netshare]
    x[netshare] <- paste(substr(y, 1, 2), gsub("\\\\", fsep, substring(y, 3)), sep="")
  }else{
    x <- gsub("\\\\", fsep, x)
  }
  x
}

splitPathFile <- function(x){
  fsep <- .Platform$file.sep
  x <- standardPathFile(x)
  n <- nchar(x)
  pos <- regexpr(paste(fsep, "[^", fsep, "]*$", sep=""), x)
  pos[pos<0] <- 0L
  path <- substr(x, 1, pos-1L)
  file <- substr(x, pos+1L, n)
  ratherpath <- !pos & !is.na(match(file, c(".", "..", "~")))
  if (any(ratherpath)){
    path[ratherpath] <- file[ratherpath]
    file[ratherpath] <- ""
  }
  fsep <- rep(fsep, length(pos))
  fsep[!pos] <- ""
  list(path=path, fsep=fsep, file=file)
}