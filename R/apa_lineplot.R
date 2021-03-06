#' Lineplot for factorial designs that conform to APA guidelines
#'
#' Wrapper function that creates one or more lineplots from a data.frame containing data from
#' a factorial design and sets APA-friendly defaults. It sequentially calls \code{\link{plot}},
#' \code{\link{axis}}, \code{\link{points}}, \code{\link{lines}}, \code{\link{arrows}} and
#' \code{\link{legend}}, that may be further customized.
#'
#'
#' @param data A \code{data.frame} that contains the data.
#' @param id Character. Variable name that identifies subjects.
#' @param factors Character. A vector of up to 4 variable names that is used to stratify the data.
#' @param dv Character. The name of the dependent variable.
#' @param tendency Closure. A function that will be used as measure of central tendency.
#' @param dispersion Closure. A function that will be used to construct error bars (i.e., whiskers). Defaults to
#'    \code{conf_int} for 95\% confidence intervals. See details.
#' @param level Numeric. Defines the width of the interval if confidence intervals are plotted. Defaults to 0.95
#'    for 95\% confidence intervals. Ignored if \code{dispersion} is not \code{conf_int}.
#' @param fun_aggregate Closure. The function that will be used to aggregate observations within subjects and factors
#'    before calculating descriptive statistics for each cell of the design. Defaults to \code{mean}.
#' @param na.rm Logical. Specifies if missing values are removed. Defaults to \code{TRUE}.
#' @param intercept Numeric. Adds a horizontal line to the plot. Can be either a single value or a matrix. For the matrix
#'    case, multiple lines are drawn, where the dimensions of the matrix determine the number of lines to be drawn.
#' @param args_axis An optional \code{list} that contains further arguments that may be passed to \code{\link{axis}}
#' @param args_points An optional \code{list} that contains further arguments that may be passed to \code{\link{points}}
#' @param args_lines An optional \code{list} that contains further arguments that may be passed to \code{\link{lines}}
#' @param args_arrows An optional \code{list} that contains further arguments that may be passed to \code{\link{arrows}}
#' @param args_legend An optional \code{list} that contains further arguments that may be passed to \code{\link{legend}}
#' @param ... Further arguments than can be passed to \code{\link{plot}} function.
#' @details The measure of dispersion can be either \code{conf_int} for confidence intervals, \code{se} for standard errors,
#'    or any other standard function. If \code{conf_int} is specified, you can also specify the area of the cumulative
#'    distribution function that will be covered. For instance, if you want a 98\% confindence interval, specify
#'    \code{level = 0.98}. \code{level} defaults to 0.95.
#' @seealso \code{\link{barplot}}
#' @examples
#' apa_lineplot(
#'    data = npk
#'    , id = "block"
#'    , dv = "yield"
#'    , factors = c("N")
#' )
#'
#' apa_lineplot(
#' data = npk
#'  , id = "block"
#'  , dv = "yield"
#'  , factors = c("N", "P")
#'  , args.legend = list(x = "center")
#'  , jit = 0
#' )
#'
#' apa_lineplot(
#'    data = npk
#'    , id = "block"
#'    , dv = "yield"
#'    , factors = c("N", "P", "K")
#'    , ylim = c(0, 80)
#'    , level = .34
#'    , las = 1
#' )
#'
#' @import grDevices
#' @import graphics
#' @export

apa_lineplot <- function(
  data
  , id
  , factors
  , dv
  , tendency = mean
  , dispersion = conf_int
  , level = 0.95
  , fun_aggregate = mean
  , na.rm = TRUE
  , intercept = NULL
  , args_axis = list()
  , args_points = list()
  , args_lines = list()
  , args_arrows = list()
  , args_legend = list()
  , ...
){
  # all the same like barplot:
  validate(data, check_class = "data.frame", check_NA = FALSE)
  validate(id, check_class="character", check_length = 1)
  validate(factors, check_class = "character")
  validate(length(factors), check_range = c(1,4))
  validate(tendency, check_class = "function", check_length = 1, check_NA =FALSE)
  validate(dispersion, check_class = "function", check_length = 1, check_NA = FALSE)
  validate(level, check_class = "numeric", check_range = c(0,1))
  validate(fun_aggregate, check_class = "function", check_length = 1, check_NA = FALSE)
  validate(na.rm, check_class = "logical", check_length = 1)
  validate(data, check_class = "data.frame", check_cols = c(id, dv, factors), check_NA = FALSE)
  if(!is.null(intercept)) validate(intercept, check_mode = "numeric")


  ellipsis <- list(...)
  output <- list()

  # Set defaults
  ellipsis <- defaults(ellipsis,
                       set = list(
                         id = id
                         , dv = dv
                         , factors = factors
                         , intercept = intercept
                         , reference = NULL
                       )
                       , set.if.null = list(
                         args.axis = args_axis
                         , args.points = args_points
                         , args.lines = args_lines
                         , args.arrows = args_arrows
                         , args.legend = args_legend
                         , xlab = factors[1]
                         , ylab = as.character(dv)
                         , frame.plot = FALSE
                       ))

  if(length(ellipsis$args.legend$title) == 0) {
    ellipsis$args.legend$title <- factors[2]
  } else if(ellipsis$args.legend$title == "") {
    ellipsis$args.legend$title <- NULL # Save space
  }

  # compatibility: allows aggregation function to be specified via "fun.aggregate"
  if(!is.null(ellipsis$fun.aggregate)) {
    fun_aggregate <- ellipsis$fun.aggregate
  }
  ellipsis$fun.aggregate <- NULL

  # is dplyr available?
  use_dplyr <- package_available("dplyr")

  # Prepare data
  for (i in factors){
    data[[i]]<-droplevels(as.factor(data[[i]]))
  }
  data[[id]]<-droplevels(as.factor(data[[id]]))

  # save names for beautiful plotting
  p.factors <- factors
  p.id <- id
  p.dv <- dv

  # strip whitespace from factor names
  factors <- gsub(pattern = " ", replacement = "_", factors)
  id <- gsub(pattern = " ", replacement = "_", id)
  dv <- gsub(pattern = " ", replacement = "_", dv)
  colnames(data) <- gsub(pattern = " ", replacement = "_", colnames(data))

  # remove extraneous columns from dataset
  data <- data[, c(id, factors, dv)]

  if(is.null(ellipsis$jit)){
    ellipsis$jit <- .1
  }

  if(use_dplyr) {
    ## Aggregate subject data
    aggregated <- fast_aggregate(data = data, dv = dv, factors = c(id, factors), fun = fun_aggregate)

    ## Calculate central tendencies
    yy <- fast_aggregate(data = aggregated, factors = factors, dv = dv, fun = tendency)
  } else {
    ## Aggregate subject data
    aggregated <- stats::aggregate(formula = stats::as.formula(paste0(dv, "~", paste(c(id, factors), collapse = "*"))), data = data, FUN = fun_aggregate)

    ## Calculate central tendencies
    yy <- stats::aggregate(formula = stats::as.formula(paste0(dv, "~", paste(factors, collapse = "*"))), data = aggregated, FUN = tendency)
  }


  ## Calculate dispersions
  fun_dispersion <- deparse(substitute(dispersion))
  if(fun_dispersion == "within_subjects_conf_int" || fun_dispersion == "wsci") {
    ee <- wsci(data = aggregated, id = id, factors = factors, level = level, method = "Morey", dv = dv)
  } else {
    if(fun_dispersion == "conf_int") {
      ee <- stats::aggregate(formula = stats::as.formula(paste0(dv, "~", paste(factors, collapse = "*"))), data = aggregated, FUN = dispersion, level = level)
    } else {
      if(use_dplyr) {
        ee <- fast_aggregate(data = aggregated, factors = factors, dv = dv, fun = dispersion)
      } else {
        ee <- stats::aggregate(formula = stats::as.formula(paste0(dv, "~", paste(factors, collapse = "*"))), data = aggregated, FUN = dispersion)
      }
    }
  }


  colnames(yy)[which(colnames(yy)==dv)] <- "tendency"
  colnames(ee)[which(colnames(ee)==dv)] <- "dispersion"

  y.values <- merge(yy, ee, by = factors)

  y.values$lower_limit <- apply(X = y.values[, c("tendency", "dispersion")], MARGIN = 1, FUN = function(x){sum(x[1], -x[2], na.rm = TRUE)})
  y.values$upper_limit <- apply(X = y.values[, c("tendency", "dispersion")], MARGIN = 1, FUN = sum, na.rm = TRUE)

  output$y <- y.values



  ## Adjust ylim to height of error bars
  if(is.null(ellipsis$ylim)) {
    ellipsis$ylim <- c(min(0, y.values[, "lower_limit"], na.rm = TRUE), max(y.values[, "upper_limit"], na.rm = TRUE))
  }

  ## One factor
  if(length(factors) < 3){
#     if(is.null(ellipsis$lty)){
#       ellipsis$lty <- "solid"
#     }

    ellipsis <- defaults(
      ellipsis
      , set = list(
        y.values = y.values
      )
      , set.if.null = list(

      ))
    do.call("apa.lineplot.core", ellipsis)
  }

  ## Three factors
  old.mfrow <- par("mfrow") # Save original plot architecture

  if(length(factors) == 3) {
    par(mfrow = c(1, nlevels(data[[factors[3]]])))
    tmp_main <- ellipsis$main

    # by default, only plot legend in topright plot:
    tmp_plot <- 1:nlevels(data[[factors[3]]])==nlevels(data[[factors[3]]])
    names(tmp_plot) <- levels(data[[factors[3]]])

    ellipsis$args.legend <- defaults(ellipsis$args.legend
                                     , set = list(

                                     )
                                     , set.if.null = list(
                                       plot = tmp_plot
                                     )
                           )

    if(is.null(ellipsis$args.legend$plot)) {
      ellipsis$args.legend$plot <- 1:nlevels(data[[factors[3]]])==nlevels(data[[factors[3]]])
    }

    if(length(ellipsis$args.legend$plot)!=nlevels(data[[factors[3]]])) {
      rec <- length(ellipsis$args.legend$plot) / nlevels(data[[factors[3]]])
      ellipsis$args.legend$plot <- rep(ellipsis$args.legend$plot, round(rec+1))
    }

    names(ellipsis$args.legend$plot) <- levels(data[[factors[3]]])

    for (i in levels(y.values[[factors[3]]])) {

      ellipsis.i <- defaults(ellipsis, set = list(
        main = paste0(tmp_main, c(p.factors[3],": ",i),collapse="")
        , y.values = y.values[y.values[[factors[3]]]==i, ]
      ), set.if.null = list(

      ))

      # by default, only draw legend in very right plot
      ellipsis.i$args.legend <- defaults(ellipsis.i$args.legend, set = list(plot = ellipsis$args.legend$plot[i]))

      # suppresses ylab
      if(i!=levels(y.values[[factors[3]]])[1]){
        ellipsis.i$ylab <- ""
      }

      do.call("apa.lineplot.core", ellipsis.i)
    }
    par(mfrow=old.mfrow)
  }

  ## Four factors
  if(length(factors)==4){
    par(mfrow=c(nlevels(data[[factors[3]]]),nlevels(data[[factors[4]]])))
    tmp_main <- ellipsis$main

    legend.plot <- array(FALSE, dim=c(nlevels(data[[factors[3]]]), nlevels(data[[factors[4]]])))
    legend.plot[1,nlevels(data[[factors[4]]])] <- TRUE

    ellipsis$args.legend <- defaults(ellipsis$args.legend
                                     , set = list(

                                     )
                                     , set.if.null = list(
                                       plot = legend.plot
                                     )
    )
    rownames(ellipsis$args.legend$plot) <- levels(data[[factors[3]]])
    colnames(ellipsis$args.legend$plot) <- levels(data[[factors[4]]])



    for (i in levels(y.values[[factors[3]]])){
      for (j in levels(y.values[[factors[4]]])) {
        ellipsis.i <- defaults(ellipsis, set = list(
          main = paste0(c(tmp_main,p.factors[3],": ",i," & ",p.factors[4],": ",j),collapse="")
          , y.values = y.values[y.values[[factors[3]]]==i&y.values[[factors[4]]]==j,]
        ), set.if.null = list(
          # nothing
        ))

        # by default, only draw legend in topright plot
        ellipsis.i$args.legend <- defaults(ellipsis.i$args.legend, set = list(plot = ellipsis$args.legend$plot[i, j]))

        # suppresses ylab
        if(j!=levels(y.values[[factors[4]]])[1]){
          ellipsis.i$ylab <- ""
        }
        do.call("apa.lineplot.core", ellipsis.i)
      }
    }
    par(mfrow=old.mfrow)
  }
  invisible(output)
}


apa.lineplot.core<-function(y.values, id, dv, factors, intercept=NULL, ...) {

  ellipsis <- list(...)

  # Plot
  # plot.new()

  # jittering of x coordinates
  jit <- ellipsis$jit


  factors <- gsub(factors, pattern = " ", replacement = "_")
  id <- gsub(id, pattern = " ", replacement = "_")
  dv <- gsub(dv, pattern = " ", replacement = "_")


  if(length(factors) > 1) {
    # convert to matrices
    y <- tapply(y.values[, "tendency"],list(y.values[, factors[2]], y.values[, factors[1]]), FUN=as.numeric)
    e <- tapply(y.values[, "dispersion"],list(y.values[, factors[2]], y.values[, factors[1]]), FUN=as.numeric)
    onedim <- FALSE
  } else {
    factors[2] <- "f2"
    y.values[["f2"]] <- as.factor(1)
    y <- y.values[, "tendency"]
    e <- y.values[, "dispersion"]
    onedim <- TRUE
  }

  space <- 1 - jit

  y.values$x <- as.integer(y.values[[factors[1]]]) - .5

  # Apply jittering if and only if more than two factors are specified
  if(onedim==FALSE) {
    y.values$x <- y.values$x - .5 + space/2 + (1-space)/(nlevels(y.values[[factors[[2]]]])-1) * (as.integer(y.values[[factors[2]]])-1)
  }

  l2 <- levels(y.values[[factors[2]]])

  # save parameters for multiple plot functions
  args.legend <- ellipsis$args.legend
  args.points <- ellipsis$args.points
  args.lines <- ellipsis$args.lines
  args.axis <- ellipsis$args.axis
  args.arrows <- ellipsis$args.arrows

  # save some global parameters for multiple
  if(!is.null(ellipsis$col)){
    # col
    args.points$col <- ellipsis$col
    args.lines$col <- ellipsis$col
  }
  if(!is.null(ellipsis$bg)){
    args.points$bg <- ellipsis$bg
  }


  # basic plot
  ellipsis <- defaults(
    ellipsis
    , set.if.null = list(
      xlim = c(0, max(as.integer(y.values[[factors[1]]])))
    )
    , set = list(
      xaxt = "n"
      , x = 1
      , type = "n"
      , jit = NULL
      , args.legend = NULL
      , args.points = NULL
      , args.lines = NULL
      , args.axis = NULL
      , args.arrows = NULL
      , col = NULL
      , bg = NULL
    )
  )

  do.call("plot.default", ellipsis)


  # prepare defaults for x axis
  args.axis <- defaults(args.axis
    , set = list(
      side = 1
    )
    , set.if.null = list(
      at = 1:nlevels(y.values[[factors[1]]])-.5
      , labels = levels(y.values[[factors[1]]])
      , lwd = 0
      , lwd.ticks = 1
      , pos = ellipsis$ylim[1]
    )
  )
  abline(h = ellipsis$ylim[1])


  # only draw axis if axis type is not specified or not specified as "n"
  if(is.null(args.axis$xaxt)||args.axis$xaxt!="n") {
    do.call("axis", args.axis)
  }

  # convert to matrices
  x <- tapply(y.values[, "x"],list(y.values[[factors[1]]], y.values[[factors[2]]]), as.numeric)
  y <- tapply(y.values[, "tendency"],list(y.values[[factors[1]]], y.values[[factors[2]]]), as.numeric)
  e <- tapply(y.values[, "dispersion"],list(y.values[[factors[1]]], y.values[[factors[2]]]), as.numeric)

  # prepare and draw arrows (i.e., error bars)
  args.arrows <- defaults(
    args.arrows
    , set = list(
      x0 = t(x)
      , x1 = t(x)
      , y0 = t(y-e)
      , y1 = t(y+e)
    )
    , set.if.null = list(
      angle = 90
      , code = 3
      , length = (1-space)/nlevels(y.values[[factors[[2]]]]) * 2
    )
  )

  do.call("arrows", args.arrows)

  # prepare and draw lines
  args.lines <- defaults(args.lines
                         , set = list(
                           x = x
                           , y = y
                         )
                         , set.if.null = list(
                           lty = 1:6
                           , col = rep("black", length(l2))
                         )
  )

  do.call("lines", args.lines)


  nc <- nlevels(y.values[[factors[2]]])
  colors <- (nc:1/(nc)) ^ 0.6


  # prepare and draw points
  args.points <- defaults(args.points
    , set = list(
      x = x
      , y = y
    )
    , set.if.null = list(
      pch = c(21:25,1:20)
      , col = rep("black", length(l2))
      , bg = gray(colors)
    )
  )

  do.call("points.matrix", args.points)




  # prepare and draw legend
  if(onedim==FALSE) {

    args.legend <- defaults(args.legend
        , set.if.null = list(
          x = "topright"
          , legend = levels(y.values[[factors[2]]])
          , pch = args.points$pch[1:nlevels(y.values[[factors[2]]])]
          # , border = args.points$col
          , pt.bg = args.points$bg
          , lty = args.lines$lty
          , lwd = args.lines$lwd
          , col = args.lines$col
          , bty = "n"
    ))

    do.call("legend", args.legend)
  }

  # draw intercept

  if(!is.null(intercept)){
    if(is.matrix(intercept)) {
      diff <- (ellipsis$xlim[2] - ellipsis$xlim[1])/(ncol(intercept)-1)
      x.vector <- seq(ellipsis$xlim[1], ellipsis$xlim[2], diff)
      for(i in 1:nrow(intercept)) {
        for (j in 1:ncol(intercept)) {
          lines(x = c(x.vector[j]-(diff/2), x.vector[j]+(diff/2)), y = rep(intercept[i,j], 2))
          # print(list(x = c(x.vector[j]-(diff/2), x.vector[j]+(diff/2)), y = rep(intercept[i,j], 2)))
        }
      }
    } else {
      lines(x = ellipsis$xlim, y = rep(intercept,2))
    }
  }
  return(list(ellipsis, args.axis, args.points, args.lines, args.legend))
}




#' @method lines matrix

lines.matrix <- function(x, y, type = "l", ...) {

  args <- list(...)
  args$type = type

  for (i in 1:ncol(x)){
    args.i <- lapply(X = args, FUN = sel, i)
    args.i$x <- x[, i]
    args.i$y <- y[, i]
    do.call("lines", args.i)
  }
}


#' @method points matrix

points.matrix <- function(x, y, type = "p", ...) {

  args <- list(...)
  args$type = type

  for (i in 1:ncol(x)){
    args.i <- lapply(X = args, FUN = sel, i)
    args.i$x <- unlist(x[, i])
    args.i$y <- unlist(y[, i])
    do.call("points", args.i)
  }
}

#' @method arrows matrix

arrows.matrix <- function(x0, x1, y0, y1, ...) {

  args <- list(...)

  for (i in 1:ncol(x0)){
    args.i <- lapply(X = args, FUN = sel, i)
    args.i$x0 <- x0[, i]
    args.i$x1 <- x1[, i]
    args.i$y0 <- y0[, i]
    args.i$y1 <- y1[, i]
    do.call("arrows", args.i)
  }
}
