compute.aops <- function(cops.data) {

####################
	mymessage("Computing derived AOPs ...", head = "+", tail = "-")

####################
# down AOPs
	waves.d <- cops.data$EdZ.waves
	Ed0.0p <- cops.data$Ed0.0p

####################
# up   AOPs + SHADOW.CORRECTION
	shadow.coef.EuZ <- NULL
	shadow.coef.LuZ <- NULL
	shadow.band <- FALSE
	if("EuZ" %in% instruments.optics) {
		waves.u <- cops.data$EuZ.waves
		EuZ.0m <- cops.data$EuZ.0m
		EuZ.0m.linear <- cops.data$EuZ.0m.linear
		if(cops.data$SHADOW.CORRECTION) {
		  if (any(select.tab[,2]=="2")) {
		    print("Shadow band measurements available for the shadow correction")
		    ix.shadow <- which(select.tab[,2]=="2")
		    print(select.tab[ix.shadow,1])
		    SB.RData <- paste("./BIN/",select.tab[ix.shadow,1],".RData", sep="")
		    if (file.exists(SB.RData)){
		      print(paste("Loading the Shadow band data:",SB.RData))
		      load(SB.RData)
		      SB<-cops
		      shadow.band <- TRUE
		      shadow.coef.EuZ <- shadow.correction("EuZ", cops.data, SB=SB)
		    } else shadow.coef.EuZ <- shadow.correction("EuZ", cops.data)
		  } else {
		    shadow.coef.EuZ <- shadow.correction("EuZ", cops.data)
		  }
		  EuZ.0m <- EuZ.0m / shadow.coef.EuZ$EuZ.shad.correction
		  EuZ.0m.linear <- cops.data$EuZ.0m.linear / shadow.coef.EuZ$EuZ.shad.correction
		}
		# Added by Simon Belanger to deal with cases when both EuZ and LuZ are present
		if(!("LuZ" %in% instruments.optics)) {
		  LuZ.0m <- EuZ.0m / cops.data$Q.sun.nadir
	  	LuZ.0m.linear <- EuZ.0m.linear / cops.data$Q.sun.nadir
		}
	}
	if("LuZ" %in% instruments.optics) {
		waves.u <- cops.data$LuZ.waves
		LuZ.0m <- cops.data$LuZ.0m
		LuZ.0m.linear <- cops.data$LuZ.0m.linear
		if(cops.data$SHADOW.CORRECTION) {
		  if (any(select.tab[,2]=="2")) {
		    print("Shadow band measurements available for the shadow correction")
		    ix.shadow <- which(select.tab[,2]=="2")
		    print(select.tab[ix.shadow,1])
		    SB.RData <- paste("./BIN/",select.tab[ix.shadow,1],".RData", sep="")
		    if (file.exists(SB.RData)){
		      load(SB.RData)
		      SB<-cops
		      shadow.band <- TRUE
		      shadow.coef.LuZ <- shadow.correction("LuZ", cops.data, SB=SB)
		    } else shadow.coef.LuZ <- shadow.correction("LuZ", cops.data)
		  } else {
		    shadow.coef.LuZ <- shadow.correction("LuZ", cops.data)
		  }
		  LuZ.0m <- LuZ.0m / shadow.coef.LuZ$LuZ.shad.correction
		  LuZ.0m.linear <- LuZ.0m.linear / shadow.coef.LuZ$LuZ.shad.correction

		}
		if(!("EuZ" %in% instruments.optics)) {
		  EuZ.0m <- LuZ.0m * cops.data$Q.sun.nadir
		  EuZ.0m.linear <- LuZ.0m.linear * cops.data$Q.sun.nadir
		}
	}
####################

	if (cops.data$EXTRAPOLATION.0m) {
	  mymessage("Computing Lw.0p ...", head = "-")
	  Lw.0p <- LuZ.0m * (1 - rau.Fresnel) / indice.water^2
	  Lw.0p.linear <- LuZ.0m.linear * (1 - rau.Fresnel) / indice.water^2
	  PLOT.LINEAR <- !all(is.na(LuZ.0m.linear))

	  mymessage("Computing nLw.0p ...", head = "-")
	  nLw.0p <- Lw.0p / Ed0.0p * etirr(waves.u)
	  nLw.0p.linear <- Lw.0p.linear / Ed0.0p * etirr(waves.u)

	  mymessage("Computing Rrs.0p ...", head = "-")
	  Rrs.0p <- Lw.0p / Ed0.0p
	  Rrs.0p.linear <- Lw.0p.linear / Ed0.0p

	  mymessage("Computing Ed0.0m ...", head = "-")
	  Ed0.0m <- 0.96 * Ed0.0p

	  mymessage("Computing R.0m ...", head = "-")
	  R.0m <- EuZ.0m / Ed0.0m
	  R.0m.linear <- EuZ.0m.linear / Ed0.0m

	  mymessage("Computing R.0p ...", head = "-")
	  R.0p <- EuZ.0m / Ed0.0p / 0.96
	  R.0p.linear <- EuZ.0m.linear / Ed0.0p / 0.96

	  mymessage("Computing Forel-Ule Color ...", head = "-")
	  FU <- Rrs2FU(waves.u, Rrs.0p)$FU
	  if (PLOT.LINEAR) {
	    FU.linear <- Rrs2FU(waves.u, Rrs.0p.linear)$FU
	  } else FU.linear <- NA

	  if (("LuZ" %in% instruments.optics) && ("EuZ" %in% instruments.optics)) {
	    mymessage("Computing Q factor ...", head = "-")
	    Q <- EuZ.0m / LuZ.0m
	    if (PLOT.LINEAR) {
	      Q.linear <- EuZ.0m.linear / LuZ.0m.linear
	    } else Q.linear <- NA

	    ## Set NA to unrealistic values due to noise
	    Q[Q>10] <-NA
	    Q.linear[Q.linear>10] <-NA
	  } else {
	    Q <- NULL
	    Q.linear <- NULL
	  }
	} else {
	  Lw.0p <- NULL
	  Lw.0p.linear <- NULL
	  nLw.0p <- NULL
	  nLw.0p.linear <- NULL
	  Rrs.0p <- NULL
	  Rrs.0p.linear <- NULL
	  Ed0.0m <- NULL
	  R.0m <- NULL
	  R.0m.linear <- NULL
	  R.0p <- NULL
	  R.0p.linear <-NULL
	  FU <- NULL
	  FU.linear <- NULL
	  Q <- NULL
	  Q.linear <- NULL
	}


# PLOT
	if (cops.data$EXTRAPOLATION.0m) {
	  if(INTERACTIVE) x11(width = win.width, height = win.height)
	  par(mfrow = c(2, 3))
	  plot(1, 1, type = "n", log = "y", xlim = range(waves.u), ylim = c(0.00005, 10), xlab = expression(lambda ~~ nm), ylab = expression(L[w]), axes = FALSE, frame.plot = TRUE)
	  axis(1)
	  axis.log(2, grid = TRUE, col = 1, lwd = 0.5, lty = 2)
	  lines(waves.u, Lw.0p, type = "b")
	  plot(1, 1, type = "n", log = "y", xlim = range(waves.u), ylim = c(0.00005, 10), xlab = expression(lambda ~~ nm), ylab = expression(nL[w]), axes = FALSE, frame.plot = TRUE)
	  axis(1)
	  axis.log(2, grid = TRUE, col = 1, lwd = 0.5, lty = 2)
	  lines(waves.u, nLw.0p, type = "b")
	  plot(1, 1, type = "n", log = "y", xlim = range(waves.u), ylim = c(0.000005, 0.1), xlab = expression(lambda ~~ nm), ylab = expression(R[0*"-"]), axes = FALSE, frame.plot = TRUE)
	  axis(1)
	  axis.log(2, grid = TRUE, col = 1, lwd = 0.5, lty = 2)
	  lines(waves.u, R.0m, type = "b")
	  plot(1, 1, type = "n", log = "y", xlim = range(waves.u), ylim = c(0.000005, 0.1), xlab = expression(lambda ~~ nm), ylab = expression(Rrs[0*"+"]), axes = FALSE, frame.plot = TRUE)
	  axis(1)
	  axis.log(2, grid = TRUE, col = 1, lwd = 0.5, lty = 2)
	  lines(waves.u, Rrs.0p, type = "b")
	  if(!is.null(shadow.coef.EuZ)) {
	    if(is.na(cops.data$chl)) {
	      shadow.correction.type <- "measured absorption"
	    } else {
	      if (cops.data$chl == 999) {
	        shadow.correction.type <- paste("absorption estimated from Kd and R", shadow.coef.EuZ$SHADOW.CORRECTION.FROM.KD)

	      } else {
	        shadow.correction.type <- "absorption from chlorophyll\ncase 1 waters model"
	      }
	    }
	    plot(waves.u, shadow.coef.EuZ$EuZ.shad.correction, type = "b", xlim = range(waves.u), ylim = c(0.2, 1), xlab = expression(lambda ~~ nm), ylab = "shadow correction for EuZ", main = shadow.correction.type)
	    abline(h = seq(0.2, 1, 0.1), lty = 3)
	  } else {
	    if("EuZ" %in% cops.data$instruments.optics) {
	      plot(1, 1, type = "n", axes = FALSE, ann = FALSE)
	      text(1, 1, "NO SHADOW CORRECTION FOR EuZ", adj = c(0.5, 0.5))
	    }
	  }
	  if(!is.null(shadow.coef.LuZ)) {
	    if(is.na(cops.data$chl)) {
	      shadow.correction.type <- "measured absorption"
	    } else 	{
	      if (cops.data$chl == 999) {
	        shadow.correction.type <- paste("absorption estimated from Kd and R", shadow.coef.LuZ$SHADOW.CORRECTION.FROM.KD)

	      } else {
	        shadow.correction.type <- "absorption from chlorophyll\ncase 1 waters model"
	      }
	    }
	    plot(waves.u, shadow.coef.LuZ$LuZ.shad.correction, type = "b",
	         xlim = range(waves.u), ylim = c(0.2, 1),
	         xlab = expression(lambda ~~ nm),
	         ylab = "shadow correction for LuZ",
	         main = shadow.correction.type)
	    abline(h = seq(0.2, 1, 0.1), lty = 3)
	  } else {
	    if("LuZ" %in% cops.data$instruments.optics) {
	      plot(1, 1, type = "n", axes = FALSE, ann = FALSE)
	      text(1, 1, "NO SHADOW CORRECTION FOR LuZ", adj = c(0.5, 0.5))
	    }
	  }
	}

	if(!is.null(Q)) {
	  par(mfrow = c(2, 1))
	  plot(waves.u,Q, xlab = expression(lambda ~~ nm),
	       ylab = "Measured Q factor", type = "l", lwd=2)
	  if (PLOT.LINEAR) lines(waves.u,Q.linear,lty=2, lwd=2)
	  legend("topright", c("linear fit", "LOESS fit"), lwd=c(2,2), lty=c(2,1))

	  plot(1, 1, type = "n", log = "y", xlim = range(waves.u),
	       ylim = c(0.00005, 0.1),
	       xlab = expression(lambda ~~ nm),
	       ylab = "Subsurface reflectance, R(0-)", axes = FALSE, frame.plot = TRUE)
	  axis(1)
	  axis.log(2, grid = TRUE, col = 1, lwd = 0.5, lty = 2)
	  lines(waves.u, R.0m, type = "b", lwd=2)
	  lines(waves.u, pi*LuZ.0m/Ed0.0m, lwd=2, col=2)
	  if (PLOT.LINEAR) lines(waves.u, R.0m.linear, type = "b", lty =2, lwd=2)
	  if (PLOT.LINEAR) lines(waves.u, pi*LuZ.0m.linear/Ed0.0m, lty =2, col=2, lwd=2)
	  legend("topright", c("LOESS", "Lu0m*pi LOESS", "Linear","Lu0m*pi linear"),
	         col=c(1,2,1,2), lty=c(1,1,2,2))
	}
	par(mfrow = c(1, 1))

	if(!is.null(shadow.coef.EuZ) & !is.null(shadow.coef.LuZ)) shadow.list <- c(shadow.coef.EuZ, shadow.coef.EuZ)
	if(!is.null(shadow.coef.EuZ) &  is.null(shadow.coef.LuZ)) shadow.list <- shadow.coef.EuZ
	if( is.null(shadow.coef.EuZ) & !is.null(shadow.coef.LuZ)) shadow.list <- shadow.coef.LuZ
	if( is.null(shadow.coef.EuZ) &  is.null(shadow.coef.LuZ)) shadow.list <- NULL

	return(c(shadow.list, list(
		Lw.0p = Lw.0p,
		nLw.0p = nLw.0p,
		R.0m = R.0m,
		R.0p = R.0p,
		Rrs.0p = Rrs.0p,
		Lw.0p.linear = Lw.0p.linear,
		nLw.0p.linear = nLw.0p.linear,
		R.0m.linear = R.0m.linear,
		R.0p.linear = R.0p.linear,
		Rrs.0p.linear = Rrs.0p.linear,
		FU = FU,
		FU.linear = FU.linear,
		Q = Q,
		Q.linear = Q.linear,
		shadow.band=shadow.band
	)))
}
