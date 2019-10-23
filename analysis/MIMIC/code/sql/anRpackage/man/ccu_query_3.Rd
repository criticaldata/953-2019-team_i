\name{ccu_query_3}
\alias{ccu_query_3}
\docType{data}
\title{
%%   ~~ data name/kind ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
}
\usage{data("ccu_query_3")}
\format{
  The format is:
 chr "SELECT\n  pvt.hadm_id, pvt.subject_id, pvt.icustay_id\n\n  , min(CASE WHEN label = 'ANION GAP' THEN valuenum EL"| __truncated__
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
data(ccu_query_3)
## maybe str(ccu_query_3) ; plot(ccu_query_3) ...
}
\keyword{datasets}
