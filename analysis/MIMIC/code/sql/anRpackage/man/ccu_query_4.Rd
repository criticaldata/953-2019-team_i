\name{ccu_query_4}
\alias{ccu_query_4}
\docType{data}
\title{
%%   ~~ data name/kind ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
}
\usage{data("ccu_query_4")}
\format{
  The format is:
 chr "  SELECT pvt.hadm_id, pvt.subject_id, pvt.icustay_id\n\n-- Easier names\n, min(case when VitalID = 1 then value"| __truncated__
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
data(ccu_query_4)
## maybe str(ccu_query_4) ; plot(ccu_query_4) ...
}
\keyword{datasets}
