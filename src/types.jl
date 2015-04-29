#------------------------------------------------------------------# OnlineStat
abstract OnlineStat

# Possibly multiple parameters that are all scalars
abstract ScalarStat <: OnlineStat

# may include scalar and vector parameters
abstract VectorStat <: OnlineStat

# Estimation of parametric distribution
abstract DistributionStat <: OnlineStat



typealias VecF Vector{Float64}
typealias MatF Vector{Float64}
