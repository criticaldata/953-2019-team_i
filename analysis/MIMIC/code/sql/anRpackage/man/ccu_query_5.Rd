\name{ccu_query_5}
\alias{ccu_query_5}
\docType{data}
\title{
%%   ~~ data name/kind ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
}
\usage{data("ccu_query_5")}
\format{
  The format is:
 chr "SELECT * FROM `physionet-data.mimiciii_derived.uofirstday`\nWHERE icustay_id in\n(\nSELECT icustay_id\nFROM (\n"| __truncated__
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
data(ccu_query_5)
## maybe str(ccu_query_5) ; plot(ccu_query_5) ...
}
\keyword{datasets}
