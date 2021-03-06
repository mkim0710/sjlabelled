#' @title Convert variable into factor and keep value labels
#' @name as_factor
#'
#' @description This function converts a variable into a factor, but preserves
#'                variable and value label attributes.
#'
#' @param x A vector or data frame.
#' @param ... Optional, unquoted names of variables that should be selected for
#'          further processing. Required, if \code{x} is a data frame (and no
#'          vector) and only selected variables from \code{x} should be processed.
#'          You may also use functions like \code{:} or tidyselect's
#'          \code{\link[tidyselect]{select_helpers}}.
#'          See 'Examples'.
#' @param add.non.labelled Logical, if \code{TRUE}, non-labelled values also
#'          get value labels.
#'
#' @return A factor, including variable and value labels. If \code{x}
#'           is a data frame, the complete data frame \code{x} will be returned,
#'           where variables specified in \code{...} are coerced
#'           to factors (including variable and value labels);
#'           if \code{...} is not specified, applies to all variables in the
#'           data frame.
#'
#' @note This function is intended for use with vectors that have value and variable
#'        label attributes. Unlike \code{\link{as.factor}}, \code{as_factor} converts
#'        a variable into a factor and preserves the value and variable label attributes.
#'        \cr \cr
#'        Adding label attributes is automatically done by importing data sets
#'        with one of the \code{read_*}-functions, like \code{\link{read_spss}}.
#'        Else, value and variable labels can be manually added to vectors
#'        with \code{\link{set_labels}} and \code{\link{set_label}}.
#'
#' @details \code{as_factor} converts numeric values into a factor with numeric
#'            levels. \code{\link{as_label}}, however, converts a vector into
#'            a factor and uses value labels as factor levels.
#'
#' @examples
#' library(sjmisc)
#' data(efc)
#' # normal factor conversion, loses value attributes
#' x <- as.factor(efc$e42dep)
#' frq(x)
#'
#' # factor conversion, which keeps value attributes
#' x <- as_factor(efc$e42dep)
#' frq(x)
#'
#' # create parially labelled vector
#' x <- set_labels(
#'   efc$e42dep,
#'   labels = c(
#'     `1` = "independent",
#'     `4` = "severe dependency",
#'     `9` = "missing value"
#'  ))
#'
#' # only copy existing value labels
#' as_factor(x)
#' get_labels(as_factor(x), include.values = "p")
#'
#' # also add labels to non-labelled values
#' as_factor(x, add.non.labelled = TRUE)
#' get_labels(as_factor(x, add.non.labelled = TRUE), include.values = "p")
#'
#'
#' # easily coerce specific variables in a data frame to factor
#' # and keep other variables, with their class preserved
#' as_factor(efc, e42dep, e16sex, c172code)
#'
#' # use select-helpers from dplyr-package
#' library(dplyr)
#' as_factor(efc, contains("cop"), c161sex:c175empl)
#'
#'
#' @importFrom tibble as_tibble
#' @export
as_factor <- function(x, ..., add.non.labelled = FALSE) {
  # evaluate arguments, generate data
  .dat <- get_dot_data(x, dplyr::quos(...))

  if (is.data.frame(x)) {
    # iterate variables of data frame
    for (i in colnames(.dat)) {
      x[[i]] <- to_fac_helper(.dat[[i]], add.non.labelled)
    }
    # coerce to tibble
    x <- tibble::as_tibble(x)
  } else {
    x <- to_fac_helper(.dat, add.non.labelled)
  }

  x
}


to_fac_helper <- function(x, add.non.labelled) {
  # is already factor?
  if (is.factor(x)) return(x)

  # retrieve value labels
  lab <-
    get_labels(
      x,
      attr.only = TRUE,
      include.values = "n",
      include.non.labelled = add.non.labelled
    )

  # retrieve variable labels
  varlab <- get_label(x)

  # switch value and names attribute, since get_labels
  # returns the values as names, and the value labels
  # as "vector content"
  if (!is.null(lab)) {
    if (is.character(x) || (is.factor(x) && !is.num.fac(x)))
      lab.switch <- names(lab)
    else
      lab.switch <- as.numeric(names(lab))

    names(lab.switch) <- as.character(lab)
  } else {
    lab.switch <- NULL
  }

  # convert variable to factor
  x <- factor(x, exclude = c(NA_character_, "NaN"))

  # set back value labels
  x <-
    suppressMessages(
      set_labels(
        x,
        labels = lab.switch,
        force.labels = TRUE,
        force.values = FALSE
      )
    )

  # set back variable labels
  x <- set_label(x, label = varlab)

  x
}
