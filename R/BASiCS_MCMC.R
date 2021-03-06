#' @title BASiCS MCMC sampler
#'
#' @description MCMC sampler to perform Bayesian inference for single-cell
#' mRNA sequencing datasets using the model described in Vallejos et al (2015).
#'
#' @param Data A \code{\linkS4class{SingleCellExperiment}} object.
#' If \code{WithSpikes = TRUE}, this MUST be formatted to include
#' the spike-ins information (see vignette).
#' @param N Total number of iterations for the MCMC sampler.
#' Use \code{N>=max(4,Thin)}, \code{N} being a multiple of \code{Thin}.
#' @param Thin Thining period for the MCMC sampler. Use \code{Thin>=2}.
#' @param Burn Burn-in period for the MCMC sampler. Use \code{Burn>=1},
#' \code{Burn<N}, \code{Burn} being a multiple of \code{Thin}.
#' @param Regression  If \code{Regression = TRUE}, BASiCS exploits a joint prior
#' formulation for mean and over-dispersion parameters to estimate a measure of
#' residual over-dispersion is not confounded by mean expression. Recommended
#' setting is \code{Regression = TRUE}.
#' @param WithSpikes  If \code{WithSpikes = TRUE}, BASiCS will use reads from
#' added spike-ins to estimate technical variability. If \code{WithSpikess = FALSE},
#' BASiCS depends on replicated experiments (batches) to estimate
#' technical variability. In this case, please supply the BatchInfo vector
#' in \code{colData(Data)}. Default: \code{WithSpikes = TRUE}.
#' @param ... Optional parameters.
#' \describe{
#' \item{\code{PriorDelta}}{Specifies the prior used for \code{delta}.
#' Possible values are 'gamma' (Gamma(\code{a.theta},\code{b.theta}) prior) and
#' 'log-normal' (log-Normal(\code{0},\code{s2.delta}) prior) .}.
#' Default value: \code{PriorDelta = 'log-normal'}.
#' \item{\code{PriorParam}}{List of 7 elements, containing the hyper-parameter
#' values required for the adopted prior (see Vallejos et al, 2015, 2016).
#' All elements must be positive real numbers.
#' \describe{
#'   \item{\code{s2.mu}}{Scale hyper-parameter for the
#'         log-Normal(\code{0},\code{s2.mu}) prior that is shared by all
#'         gene-specific expression rate parameters \eqn{\mu_i}.
#'         Default: \code{s2.mu = 0.5}.}
#'   \item{\code{s2.delta}}{Only used when `PriorDelta == 'log-normal'`.
#'         Scale hyper-parameter for the log-Normal(\code{0},\code{s2.delta})
#'         prior that is shared by all gene-specific over-dispersion parameters
#'         \eqn{\delta_i}. Default: \code{s2.delta = 0.5}. }
#'   \item{\code{a.delta}}{Only used when `PriorDelta == 'gamma'`.
#'         Shape hyper-parameter for the Gamma(\code{a.delta},\code{b.delta})
#'         prior that is shared by all gene-specific biological over-dispersion
#'         parameters \eqn{\delta_i}. Default: \code{a.delta = 1}.}
#'   \item{\code{b.delta}}{Only used when `PriorDelta == 'gamma'`.
#'         Rate hyper-parameter for the Gamma(\code{a.delta},\code{b.delta})
#'         prior that is shared by all gene-specific biological over-dispersion
#'         hyper-parameters \eqn{\delta_i}. Default: \code{b.delta = 1}.}
#'   \item{\code{p.phi}}{Dirichlet hyper-parameter for the joint of all
#'         (scaled by \code{n}) cell-specific mRNA content normalising
#'         constants \eqn{\phi_j / n}.
#'         Default: \code{p.phi} \code{= rep(1, n)}.}
#'   \item{\code{a.s}}{Shape hyper-parameter for the
#'         Gamma(\code{a.s},\code{b.s}) prior that is shared by all
#'         cell-specific capture efficiency normalising constants \eqn{s_j}.
#'         Default: \code{a.s = 1}.}
#'   \item{\code{b.s}}{Rate hyper-parameter for the Gamma(\code{a.s},
#'         \code{b.s}) prior that is shared by all cell-specific capture
#'         efficiency normalising constants \eqn{s_j}.
#'         Default: \code{b.s = 1}.}
#'   \item{\code{a.theta}}{Shape hyper-parameter for the
#'         Gamma(\code{a.theta},\code{b.theta}) prior for technical noise
#'         parameter \eqn{\theta}. Default: \code{a.theta = 1}.}
#'   \item{\code{b.theta}}{Rate hyper-parameter for the
#'         Gamma(\code{a.theta},\code{b.theta}) prior for technical noise
#'         parameter \eqn{\theta}. Default: \code{b.theta = 1}.}
#'  \item{\code{eta}}{Only used when \code{Regression = TRUE}. \code{eta}
#'       specifies the degress of freedom for the residual term.
#'       Default: \code{eta = 5}.}.
#'
#' }}
#' \item{\code{k}}{Only used when \code{Regression = TRUE}. \code{k} specifies
#'       the number of regression Gaussian Radial Basis Functions (GRBF) used
#'       within the correlated prior adopted for gene-specific over-dispersion
#'       and mean expression paramters. Default: \code{k = 12}. }
#' \item{\code{Var}}{Only used when \code{Regression = TRUE}. \code{Var}
#'       specifies the GRBF scaling parameter. Default: \code{Var = 1.2}. }
#' \item{\code{AR}}{Optimal acceptance rate for adaptive Metropolis Hastings
#'       updates. It must be a positive number between 0 and 1. Default
#'       (and recommended): \code{AR = 0.44}}.
#' \item{\code{StopAdapt}}{Iteration at which adaptive proposals are not longer
#'       adapted. Use \code{StopAdapt>=1}. Default: \code{StopAdapt = Burn}.}
#' \item{\code{StoreChains}}{If \code{StoreChains = TRUE}, the generated
#'       \code{BASiCS_Chain} object is stored as a `.Rds` file (\code{RunName}
#'       argument used to index the file name).
#'       Default: \code{StoreChains = FALSE}.}
#' \item{\code{StoreAdapt}}{If \code{StoreAdapt = TRUE}, trajectory of
#'       adaptive proposal variances (in log-scale) for all parameters is
#'       stored as a list in a `.Rds` file (\code{RunName} argument used to
#'       index file name). Default: \code{StoreAdapt = FALSE}.}
#' \item{\code{StoreDir}}{Directory where output files are stored.
#'       Only required if \code{StoreChains = TRUE} and/or
#'       \code{StoreAdapt = TRUE}). Default: \code{StoreDir = getwd()}.}
#' \item{\code{RunName}}{String used to index `.Rds` files storing chains
#'       and/or adaptive proposal variances.}
#' \item{\code{PrintProgress}}{If \code{PrintProgress = FALSE}, console-based
#'       progress report is suppressed.}
#' \item{\code{Start}}{Starting values for the MCMC sampler. We do not advise
#'       to use this argument. Default options have been tuned to facilitate
#'       convergence. If changed, it must be a list containing the following
#'       elements: \code{mu0}, \code{delta0}, \code{phi0}, \code{s0},
#'       \code{nu0}, \code{theta0}, \code{ls.mu0}, \code{ls.delta0},
#'       \code{ls.phi0}, \code{ls.nu0} and \code{ls.theta0}}
#' }
#'
#' @return An object of class \code{\link[BASiCS]{BASiCS_Chain}}.
#'
#' @examples
#'
#' # Built-in simulated dataset
#' set.seed(1) 
#' Data <- makeExampleBASiCS_Data()
#' # To analyse real data, please refer to the instructions in:
#' # https://github.com/catavallejos/BASiCS/wiki/2.-Input-preparation
#'
#' # Only a short run of the MCMC algorithm for illustration purposes
#' # Longer runs migth be required to reach convergence
#' Chain <- BASiCS_MCMC(Data, N = 50, Thin = 2, Burn = 10, Regression = FALSE,
#'                      PrintProgress = FALSE, WithSpikes = TRUE)
#'
#' # To run the regression version of BASiCS, use:
#' Chain <- BASiCS_MCMC(Data, N = 50, Thin = 2, Burn = 10, Regression = TRUE,
#'                      PrintProgress = FALSE, WithSpikes = TRUE)
#'
#' # To run the non-spike version BASiCS requires the data to contain at least
#' # 2 batches:
#' set.seed(2)
#' Data <- makeExampleBASiCS_Data(WithBatch = TRUE)
#' Chain <- BASiCS_MCMC(Data, N = 50, Thin = 2, Burn = 10, Regression = TRUE,
#'                      PrintProgress = FALSE, WithSpikes = FALSE)
#'
#' # For illustration purposes we load a built-in 'BASiCS_Chain' object
#' # (obtained using the 'BASiCS_MCMC' function)
#' data(ChainSC)
#'
#' # `displayChainBASiCS` can be used to extract information from this output.
#' # For example:
#' head(displayChainBASiCS(ChainSC, Param = 'mu'))
#'
#' # Traceplot (examples only)
#' plot(ChainSC, Param = 'mu', Gene = 1)
#' plot(ChainSC, Param = 'phi', Cell = 1)
#' plot(ChainSC, Param = 'theta', Batch = 1)
#'
#' # Calculating posterior medians and 95% HPD intervals
#' ChainSummary <- Summary(ChainSC)
#'
#' # `displaySummaryBASiCS` can be used to extract information from this output
#' # For example:
#' head(displaySummaryBASiCS(ChainSummary, Param = 'mu'))
#'
#' # Graphical display of posterior medians and 95% HPD intervals
#' # For example:
#' plot(ChainSummary, Param = 'mu', main = 'All genes')
#' plot(ChainSummary, Param = 'mu', Genes = 1:10, main = 'First 10 genes')
#' plot(ChainSummary, Param = 'phi', main = 'All cells')
#' plot(ChainSummary, Param = 'phi', Cells = 1:5, main = 'First 5 cells')
#' plot(ChainSummary, Param = 'theta')
#'
#' # To constrast posterior medians of cell-specific parameters
#' # For example:
#' par(mfrow = c(1,2))
#' plot(ChainSummary, Param = 'phi', Param2 = 's', SmoothPlot = FALSE)
#' # Recommended for large numbers of cells
#' plot(ChainSummary, Param = 'phi', Param2 = 's', SmoothPlot = TRUE)
#'
#' # To constrast posterior medians of gene-specific parameters
#' par(mfrow = c(1,2))
#' plot(ChainSummary, Param = 'mu', Param2 = 'delta', log = 'x',
#'      SmoothPlot = FALSE)
#' # Recommended
#' plot(ChainSummary, Param = 'mu', Param2 = 'delta', log = 'x',
#'      SmoothPlot = TRUE)
#'
#' # To obtain denoised rates / counts, see:
#' # help(BASiCS_DenoisedRates)
#' # and
#' # help(BASiCS_DenoisedCounts)
#'
#' # For examples of differential analyses between 2 populations of cells see:
#' # help(BASiCS_TestDE)
#'
#' @author Catalina A. Vallejos \email{cnvallej@@uc.cl}
#' @author Nils Eling \email{eling@@ebi.ac.uk}
#'
#' @references
#' Vallejos, Marioni and Richardson (2015). PLoS Computational Biology.
#'
#' Vallejos, Richardson and Marioni (2016). Genome Biology.
#'
#' Eling et al (2018). Cell Systems
#' @export
BASiCS_MCMC <- function(Data, N, Thin, Burn, Regression,
                        WithSpikes = TRUE, ...)
{
  # Checks to ensure input arguments are valid
  HiddenBASiCS_MCMC_InputCheck(Data, N, Thin, Burn, Regression, WithSpikes)

  # Some global values used throughout the MCMC algorithm and checks
  # If data contains spike-ins
  if (!is.null(SingleCellExperiment::isSpike(Data))) {
    q <- nrow(Data)
    q.bio <- sum(!SingleCellExperiment::isSpike(Data))
    spikes <- SingleCellExperiment::isSpike(Data)
    BioCounts <- counts(Data)[!spikes, ]
  }
  else {
    BioCounts <- counts(Data)
    q.bio <- q <- nrow(Data)
    spikes <- rep(FALSE, q)
  }

  n <- dim(counts(Data))[2]

  # If Data contains batches
  if(!is.null(colData(Data)$BatchInfo)){
    # Store the correct number of levels in batch vector
    BatchInfo <- as.factor(colData(Data)$BatchInfo)
    BatchInfo <- factor(BatchInfo, levels = unique(BatchInfo))
    nBatch <- length(unique(BatchInfo))
  }
  else{
    BatchInfo <- rep(1, times = n)
    nBatch <- 1
  }

  sum.bycell.all <- matrixStats::rowSums2(counts(Data))
  sum.bygene.all <- matrixStats::colSums2(counts(Data))

  sum.bycell.bio <- matrixStats::rowSums2(BioCounts)
  sum.bygene.bio <- matrixStats::colSums2(BioCounts)

  # Assignment of default values
  ArgsDef <- HiddenBASiCS_MCMC_ExtraArgs(Data,
                                         Burn,
                                         n,
                                         Regression,
                                         WithSpikes = WithSpikes,
                                         ...)
  AR <- ArgsDef$AR
  StopAdapt <- ArgsDef$StopAdapt
  StoreChains <- ArgsDef$StoreChains
  StoreAdapt <- ArgsDef$StoreAdapt
  StoreDir <- ArgsDef$StoreDir
  RunName <- ArgsDef$RunName
  PrintProgress <- ArgsDef$PrintProgress
  PriorParam <- ArgsDef$PriorParam
  PriorDeltaNum <- ArgsDef$PriorDeltaNum
  PriorDelta <- ArgsDef$PriorDelta
  k <- ArgsDef$k
  variance <- ArgsDef$variance
  Start <- ArgsDef$Start
  StochasticRef <- ArgsDef$StochasticRef
  ConstrainType <- ArgsDef$ConstrainType
  ConstrainProp <- ArgsDef$ConstrainProp

  # Starting values for MCMC chains
  mu0 <- as.vector(Start$mu0)[!spikes]
  delta0 <- as.vector(Start$delta0)
  phi0 <- as.vector(Start$phi0)
  s0 <- as.vector(Start$s0)
  nu0 <- as.vector(Start$nu0)
  theta0 <- as.numeric(Start$theta0)


  # Starting values for adaptive proposal variances
  ls.mu0 <- as.vector(Start$ls.mu0)
  ls.delta0 <- as.vector(Start$ls.delta0)
  ls.phi0 <- as.numeric(Start$ls.phi0)
  ls.nu0 <- as.vector(Start$ls.nu0)
  ls.theta0 <- as.numeric(Start$ls.theta0)

  # Starting values for Regression
  if (Regression) {
      beta0 <- Start$beta0
      sigma20 <- Start$sigma20
      lambda0 <- Start$lambda0
  }

  # Parameters associated to the presence of batches
  if(nBatch > 1) {
    BatchDesign <- model.matrix(~BatchInfo - 1)  
  } else { 
    # If there are no batches or the user asked to ignore them
    BatchDesign <- matrix(1, nrow = n, ncol = 1) 
    nBatch <- 1
  }

  # If spikes are available
  if (WithSpikes) {
    SpikeInput <- metadata(Data)$SpikeInput

    # If regression case is chosen
    if (Regression) {
      message("Running with spikes BASiCS sampler (regression case) ... \n")
      Time <- system.time(Chain <- HiddenBASiCS_MCMCcppReg(
                N,
                Thin,
                Burn,
                as.matrix(BioCounts),
                BatchDesign,
                SpikeInput,
                mu0,
                delta0,
                phi0,
                s0,
                nu0,
                rep(theta0, nBatch),
                PriorParam$s2.mu,
                PriorParam$p.phi,
                PriorParam$a.s,
                PriorParam$b.s,
                PriorParam$a.theta,
                PriorParam$b.theta,
                AR,
                ls.mu0,
                ls.delta0,
                ls.phi0,
                ls.nu0,
                rep(ls.theta0, nBatch),
                sum.bycell.all,
                sum.bycell.bio,
                sum.bygene.all,
                sum.bygene.bio,
                as.numeric(StoreAdapt),
                StopAdapt,
                as.numeric(PrintProgress),
                k,
                PriorParam$m,
                PriorParam$V,
                PriorParam$a.sigma2,
                PriorParam$b.sigma2,
                beta0,
                sigma20,
                PriorParam$eta,
                lambda0,
                variance))

      # Remove epsilons for genes that are not expressed in at least 2 cells
      # Discuss this with John (potentially include an optional arg about this)
      AtLeast2Cells <- matrixStats::rowSums2(ifelse(BioCounts > 0, 1, 0)) > 1
      Chain$epsilon[,!AtLeast2Cells] <- NA
    }
    else {
      message("Running with spikes BASiCS sampler (no regression) ... \n")
      Time <- system.time(Chain <- HiddenBASiCS_MCMCcpp(
                N,
                Thin,
                Burn,
                as.matrix(BioCounts),
                BatchDesign,
                SpikeInput,
                mu0,
                delta0,
                phi0,
                s0,
                nu0,
                rep(theta0, nBatch),
                PriorParam$s2.mu,
                PriorParam$a.delta,
                PriorParam$b.delta,
                PriorParam$s2.delta,
                PriorDeltaNum,
                PriorParam$p.phi,
                PriorParam$a.s,
                PriorParam$b.s,
                PriorParam$a.theta,
                PriorParam$b.theta,
                AR,
                ls.mu0,
                ls.delta0,
                ls.phi0,
                ls.nu0,
                rep(ls.theta0, nBatch),
                sum.bycell.all,
                sum.bycell.bio,
                sum.bygene.all,
                sum.bygene.bio,
                as.numeric(StoreAdapt),
                StopAdapt,
                as.numeric(PrintProgress)))
    }
  }
  else {
#    # If spikes are not available
#    message("-------------------------------------------------------------\n",
#            "IMPORTANT: this code is under development. DO NOT USE \n",
#            "This part of the code is just a place-holder \n",
#            "-------------------------------------------------------------\n")
    # Definition of parameters that are specific to the no-spikes case
    NoSpikesParam <- HiddenBASiCS_MCMC_NoSpikesParam(
      as.matrix(BioCounts),
      ConstrainType,
      StochasticRef, q.bio, mu0, PriorDelta, ConstrainProp)
    ConstrainGene <- NoSpikesParam$ConstrainGene
    NotConstrainGene <- NoSpikesParam$NotConstrainGene
    Constrain <- NoSpikesParam$Constrain
    RefGenes <- NoSpikesParam$RefGenes; RefGene <- NoSpikesParam$RefGene
    Index <- seq_len(q.bio) - 1

    if (Regression) {
      message("Running no spikes BASiCS sampler (regression case) ... \n")
      Time <- system.time(Chain <- HiddenBASiCS_MCMCcppRegNoSpikes(
                N,
                Thin,
                Burn,
                as.matrix(BioCounts),
                BatchDesign,
                mu0,
                delta0,
                s0,
                nu0,
                rep(theta0, nBatch),
                PriorParam$s2.mu,
                PriorParam$a.s,
                PriorParam$b.s,
                PriorParam$a.theta,
                PriorParam$b.theta,
                AR,
                ls.mu0,
                ls.delta0,
                ls.nu0,
                rep(ls.theta0, nBatch),
                sum.bycell.bio,
                sum.bygene.bio,
                as.numeric(StoreAdapt),
                StopAdapt,
                as.numeric(PrintProgress),
                k,
                PriorParam$m,
                PriorParam$V,
                PriorParam$a.sigma2,
                PriorParam$b.sigma2,
                beta0,
                sigma20,
                PriorParam$eta,
                lambda0,
                variance,
                Constrain,
                Index,
                RefGene,
                RefGenes,
                ConstrainGene,
                NotConstrainGene,
                ConstrainType,
                as.numeric(StochasticRef)))
      # Remove epsilons for genes that are not expressed in at least 2 cells
      # Discuss this with John (potentially include an optional arg about this)
      AtLeast2Cells <- matrixStats::rowSums2(ifelse(BioCounts > 0, 1, 0)) > 1
      Chain$epsilon[,!AtLeast2Cells] <- NA
    }
    else {
      message("Running no spikes BASiCS sampler (no regression) ... \n")
      Time <- system.time(Chain <- HiddenBASiCS_MCMCcppNoSpikes(
        N,
        Thin,
        Burn,
        as.matrix(BioCounts),
        BatchDesign,
        mu0,
        delta0,
        s0,
        nu0,
        rep(theta0, nBatch),
        PriorParam$s2.mu,
        PriorParam$a.delta,
        PriorParam$b.delta,
        PriorParam$s2.delta,
        PriorDeltaNum,
        PriorParam$a.s,
        PriorParam$b.s,
        PriorParam$a.theta,
        PriorParam$b.theta,
        AR,
        ls.mu0,
        ls.delta0,
        ls.nu0,
        rep(ls.theta0, nBatch),
        sum.bycell.bio,
        sum.bygene.bio,
        as.numeric(StoreAdapt),
        StopAdapt,
        as.numeric(PrintProgress),
        Constrain,
        Index,
        RefGene,
        RefGenes,
        ConstrainGene,
        NotConstrainGene,
        ConstrainType,
        as.numeric(StochasticRef)))
    }
  }

  # Format column names of MCMC chains
  colnames(Chain$mu) <- colnames(Chain$delta) <- rownames(BioCounts)
  if (Regression) {
    colnames(Chain$epsilon) <- colnames(Chain$mu)
    Chain$lambda <- NULL # Remove to reduce storage
  }
  CellLabels <- paste0(colnames(counts(Data)), "_Batch", BatchInfo)
  colnames(Chain$s) <- CellLabels
  if (WithSpikes) {
    colnames(Chain$phi) <- CellLabels
  }
  colnames(Chain$nu) <- CellLabels
  colnames(Chain$theta) <- paste0("Batch", unique(BatchInfo))

  message("-------------------------------------------------------------\n",
          "MCMC running time \n",
          "-------------------------------------------------------------\n",
          "user: ", round(Time['user.self'], 3), "\n",
          "system: ", round(Time['sys.self'], 3), "\n",
          "elapsed: ", round(Time['elapsed'], 3), "\n")

  message("-------------------------------------------------------------\n",
          "Output \n",
          "-------------------------------------------------------------\n")

  # Convert output into a `BASiCS_Chain` object
  ChainClass <- newBASiCS_Chain(parameters = Chain)

  # Store chain and/or adaptive variances
  HiddenBASiCS_MCMC_OutputStore(ChainClass,
                                Chain,
                                StoreChains,
                                StoreAdapt,
                                StoreDir,
                                RunName)

  # Store reference gene information (no spikes case only)
  if (!WithSpikes) {
    if (StoreChains)
      HiddenBASiCS_MCMC_RefFreqStore(Data,
                                     Chain,
                                     RefGene,
                                     RefGenes,
                                     ConstrainType,
                                     StoreDir,
                                     RunName)
  }
  else {
    message("-------------------------------------------------------------\n",
            "BASiCS version ", packageVersion("BASiCS"), " : \n",
            "vertical integration (spikes case) \n",
            "-------------------------------------------------------------\n")
  }

  # Return `BASiCS_MCMC` object
  return(ChainClass)
}
