
# implements the online flexible least squares algorithm... modeled on Montana et al (2009):
#   "Flexible least squares for temporal data mining and statistical arbitrage"

# Our cost function: Cₜ(βₜ; μ) = (yₜ - xₜ'βₜ)² + μ Δβₜ
#   Below we use Vω = μ⁻¹Iₚ  along with a nicer to use relationship: μ = (1 - δ) / δ
#   We accept 0 <= δ <= 1 as a constructor argument which controls the weighting of new observations
#   δ close to 0 corresponds to large μ, which means the parameter vector β changes slowly
#   δ close to 1 corresponds to small μ, which means the parameter vector β changes quickly


# TODO: allow for time-varying Vω???
#  to accomplish... lets represent Vω as a vector of Var's (i.e. the diagonal of Vω)

#-------------------------------------------------------# Type and Constructors

type OnlineFLS <: OnlineStat
	p::Int  		# number of independent vars
	Vω::MatF    # pxp (const) covariance matrix of Δβₜ
	# Vω::Vector{Var}
	Vε::Var     # variance of error term... use exponential weighting with δ as the weight param

	n::Int
	β::VecF 		# the current estimate in: yₜ = Xₜβₜ + εₜ

	# these are needed to update β
	R::MatF     # pxp matrix
	q::Float64  # called Q in paper
	K::VecF     # px1 vector (equivalent to Kalman gain)

	function OnlineFLS(p::Int, δ::Float64)

		# calculate the covariance matrix Vω from the smoothing parameter δ
		@assert δ > 0. && δ <= 1.
		μ = (1. - δ) / δ
		Vω = eye(p) / μ
		println("μ = ", μ)
		println("Vω:\n", Vω)

		Vε = Var(ExponentialWeighting(δ))
		
		# create and init the object
		o = new(p, Vω, Vε)
		empty!(o)
		o
	end
end


function OnlineFLS(y::Float64, x::VecF, δ::Float64)
	p = length(x)
	o = OnlineFLS(p, δ)
	update!(o, y, x)
	o
end

function OnlineFLS(y::VecF, X::MatF, δ::Float64)
	p = size(X,2)
	o = OnlineFLS(p, δ)
	update!(o, y, X)
	o
end

#-----------------------------------------------------------------------# state

statenames(o::OnlineFLS) = [:β, :Vε, :nobs]
state(o::OnlineFLS) = Any[β(o), var(o.Vε), nobs(o)]

β(o::OnlineFLS) = o.β
Base.beta(o::OnlineFLS) = o.β

#---------------------------------------------------------------------# update!

# NOTE: assumes X mat is (T x p), where T is the number of observations
# TODO: optimize
function update!(o::OnlineFLS, y::VecF, X::MatF)
	@assert length(y) == size(X,1)
	for i in length(y)
		update!(o, y[i], vec(X[i,:]))
	end
end

function update!(o::OnlineFLS, y::Float64, x::VecF)

	# calc error and update error variance
	ε = y - dot(x, o.β)
	update!(o.Vε, ε)
	
	# update sufficient stats to get the Kalman gain
	o.R += o.Vω - (o.q * o.K) * o.K'
	Rx = o.R * x
	o.q = dot(x, Rx) + var(o.Vε)
	o.K = Rx / o.q

	@LOG y x
	# @LOG ε var(o.Vε)
	# @LOG o.R
	# @LOG Rx
	# @LOG o.q
	# @LOG o.K

	# update β
	o.β += o.K * ε

	@LOG o.β

	# finish
	o.n += 1
	return

end

# NOTE: keeps consistent p... just resets state
function Base.empty!(o::OnlineFLS)
	p = o.p
	empty!(o.Vε)
	o.n = 0
	o.β = zeros(p)
	o.R = zeros(p,p)
	o.q = 0.
	o.K = zeros(p)
end

function Base.merge!(o1::OnlineFLS, o2::OnlineFLS)
	# TODO
end


function StatsBase.coef(o::OnlineFLS)
	# TODO
end

function StatsBase.coeftable(o::OnlineFLS)
	# TODO
end

function StatsBase.confint(o::OnlineFLS, level::Float64 = 0.95)
	# TODO
end

# predicts yₜ for a given xₜ
function StatsBase.predict(o::OnlineFLS, x::VecF)
	dp = o.β[1]
	for i in 2:o.p
		dp += o.β[i] * x[i-1]
	end
	dp
end

# NOTE: uses most recent estimate of βₜ to predict the whole matrix
function StatsBase.predict(o::OnlineFLS, X::MatF)
	n = size(X,1)
	pred = zeros(n)
	for i in 1:n
		pred[i] = StatsBase.predict(o, vec(X[i,:]))
	end
	pred
end




