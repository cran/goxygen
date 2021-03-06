% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper_functions.R
\name{.interfaceplot}
\alias{.interfaceplot}
\title{.interfaceplot}
\usage{
.interfaceplot(zz, name, docfolder)
}
\arguments{
\item{zz}{a connection object of class "textConnection" containing the markdown document}

\item{name}{Name of the module for which the interfaceplot should be shown}

\item{docfolder}{folder the documentation should be written to relative to model folder}
}
\description{
helper function which includes interface plot figures in a markdown document, if available.
The figures need to be created beforehand.
}
\seealso{
\code{\link{goxygen}}, \code{\link{createModulePage}}
}
\author{
Jan Philipp Dietrich
}
