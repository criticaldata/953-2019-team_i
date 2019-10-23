\name{ccu_patients_id_los}
\alias{ccu_patients_id_los}
\docType{data}
\title{
%%   ~~ data name/kind ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of the dataset. ~~
}
\usage{data("ccu_patients_id_los")}
\format{
  A data frame with 6802 observations on the following 6 variables.
  \describe{
    \item{\code{subject_id}}{a numeric vector}
    \item{\code{hadm_id}}{a numeric vector}
    \item{\code{icustay_id}}{a numeric vector}
    \item{\code{intime}}{a POSIXct}
    \item{\code{outtime}}{a POSIXct}
    \item{\code{los}}{a numeric vector}
  }
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
data(ccu_patients_id_los)
## maybe str(ccu_patients_id_los) ; plot(ccu_patients_id_los) ...
}
\keyword{datasets}
