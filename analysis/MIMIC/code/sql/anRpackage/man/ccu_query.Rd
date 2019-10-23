\name{ccu_query}
\alias{ccu_query}
\docType{data}
\title{
%%   ~~ data name/kind ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
}
\usage{data("ccu_query")}
\format{
  The format is:
 chr "SELECT subject_id , hadm_id, icustay_id, intime, outtime, los\nFROM (\n    SELECT subject_id, hadm_id, intime, "| __truncated__
}
\details{
%%  ~~ If necessary, more details than the __description__ above ~~
}
\source{
%%  ~~ reference to a publication or URL from which the data were obtained ~~
}
\references{
%%  ~~ possibly secondary sources and usages ~~
}
\examples{
data(ccu_query)
## maybe str(ccu_query) ; plot(ccu_query) ...
}
\keyword{datasets}
