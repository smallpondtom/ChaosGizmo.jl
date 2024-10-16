export LyapunovExponentOptions, lyapunov_exponent, kaplan_yorke_dim

"""
$(TYPEDEF)

Options for Lypuanov exponents.

# Fields
- `m::Integer`: the number of the most exponents to compute
- `τ::Real`: time to simulate the system before computing exponents
- `Δt::Real`: timestep for the integrator
- `Δτ::Real`: timestep for the integrator (before computing exponents)
- `T::Real`: time between reorthogonalization steps
- `N::Integer`: the total number of reorthogonalization steps
- `ϵ::Real`: perturbation magnitude
- `verbose::Bool`: print progress to stdout
- `history::Bool`: return all LEs
- `pert_integrator::Function`: integrator for the perturbed system
- `jacobian::Bool`: use the Jacobian method
- `initialization::Symbol`: initialization method for the orthogonal directions

# Default values
- `m = 1`
- `τ = 1000`
- `Δt = 1e-2`
- `Δτ = Δt`
- `T = Δt`
- `N = 1000`
- `ϵ = 1e-6`
- `verbose = false`
- `history = false`
- `pert_integrator = nothing`
- `jacobian = false`
- `initialization = :random`

# Perturbation integrator
The perturbation integrator must be in the form of `integrator(J, Q, dt)` where `J` is the Jacobian of the system,
`Q` is the perturbation state, and `dt` is the timestep. The integrator must return the updated perturbation state.
The default integrator is the 4th order Runge-Kutta method:'

```julia
function RK4(J, Q, dt)
    # RK4 steps
    k1 = J * Q
    k2 = J * (Q + 0.5*dt*k1)
    k3 = J * (Q + 0.5*dt*k2)
    k4 = J * (Q + dt*k3)
    # Update the perturbation state
    Qnew = Q + (dt/6) * (k1 + 2*k2 + 2*k3 + k4)
    return Qnew
end
```

You can select the following explicit method integrators available in the ChaosGizmo submodule:
- `EULER(J, Q, dt)`: Euler method
- `RK2(J, Q, dt)`: 2nd order Runge-Kutta method
- `RK4(J, Q, dt)`: 4th order Runge-Kutta method
- `SSPRK3(J, Q, dt)`: 3rd order Strong Stability Preserving Runge-Kutta method
- `RALSTON4(J, Q, dt)`: Ralston's fourth-order method

# Note 
If you are using the Jacobian/Linear Tangent Map (LTM) method, T should be set equal to Δt (i.e. Δt = T) or T = 2*Δt.
"""
@with_kw struct LyapunovExponentOptions
    m::Integer = 1                       # the number of the most exponents to compute
    τ0::Real = 0.0                       # initial time 
    τ::Real = 1000                       # time to simulate the system before computing exponents
    Δt::Real = 1e-2                      # timestep for the integrator
    Δτ::Real = Δt                        # timestep for the integrator (before computing exponents)
    T::Real = Δt                         # time between reorthogonalization steps
    N::Integer = 1000                    # the total number of reorthogonalization steps
    ϵ::Real = 1e-6                       # perturbation magnitude
    verbose::Bool = false                # print progress to stdout
    history::Bool = false                # return all LEs
    pert_integrator::Function = RK4      # integrator for the perturbed system (default: RK4)
    jacobian::Bool = false               # use the Jacobian method
    initialization::Symbol = :random     # initialization method for the orthogonal directions

    @assert (Δt <= T) "The integration timestep must be smaller than or equal to the reorthogonalization time step"
    @assert initialization ∈ [:random, :unit] "Initialization method must be either :random or :unit"
end


"""
$(SIGNATURES)

Compute the Lyapunov exponents of a dynamical system using the algorirhtm in [^edson2019] which
uses the algorithm from [^benettin1980] and [^shimada1979] to compute them.

# Arguments
- `integrator::Function`: integrator for the model
- `ic::AbstractArray`: initial condition
- `options::LyapunovExponentOptions`: options for the algorithm
- `kwargs...`: keyword arguments for the integrator

# Returns
- `λ::Vector`: the Lyapunov exponents
- `λ_all::Matrix`: all Lyapunov exponents if `options.history` is `true`

# Integrator function format
The integrator function must be in the form of `integrator(tspan, ic)` where `tspan` is the time 
span to integrate over and `ic` is the initial condition. The integrator must return the solution
at the final time.  And the integrator can have additional parameters as keyword arguments `kwargs...`.

Example integrator function for the Lorenz system using the 4th order Runge-Kutta method:

```julia
function lorenz_integrator(tspan::AbstractArray, IC::Array; kwargs...)
    K = length(tspan)
    N = size(IC,1)
    f = let A = kwargs[:A], H = kwargs[:H]
        (x, t) -> A*x + H*kron(x,x)
    end
    xk = zeros(N,K)
    xk[:,1] = IC

    for k in 2:K
        timestep = tspan[k] - tspan[k-1]
        k1 = f(xk[:,k-1], tspan[k-1])
        k2 = f(xk[:,k-1] + 0.5 * timestep * k1, tspan[k-1] + 0.5 * timestep)
        k3 = f(xk[:,k-1] + 0.5 * timestep * k2, tspan[k-1] + 0.5 * timestep)
        k4 = f(xk[:,k-1] + timestep * k3, tspan[k-1] + timestep)
        xk[:,k] = xk[:,k-1] + (timestep / 6.0) * (k1 + 2*k2 + 2*k3 + k4)
    end
    return xk
end
```

# References
[^edson2019] R. A. Edson, J. E. Bunder, T. W. Mattner, and A. J. Roberts, 
“Lyapunov Exponents of the Kuramoto–Sivashinsky PDE,” The ANZIAM Journal, vol. 61,
no. 3, pp. 270–285, Jul. 2019, doi: 10.1017/S1446181119000105.

[^benettin1980] G. Benettin, L. Galgani, A. Giorgilli, and J.-M. Strelcyn, 
“Lyapunov Characteristic Exponents for smooth dynamical systems and for hamiltonian systems;
a method for computing all of them. Part 1: Theory,” Meccanica, 
vol. 15, no. 1, pp. 9–20, Mar. 1980, doi: 10.1007/BF02128236.

[^shimada1979] [1] I. Shimada and T. Nagashima, “A Numerical Approach to Ergodic Problem of
Dissipative Dynamical Systems,” Progress of Theoretical Physics, 
vol. 61, no. 6, pp. 1605–1616, Jun. 1979, doi: 10.1143/PTP.61.1605.
"""
function lyapunov_exponent_fullmodel(
    integrator::Function,               # integrator for the model
    ic::AbstractArray,                  # initial condition
    options::LyapunovExponentOptions;   # options for the algorithm
    kwargs...                           # keyword arguments for the integrator
    )

    # Unpack options
    m = options.m
    τ = options.τ
    T = options.T
    N = options.N
    ϵ = options.ϵ
    Δt = options.Δt
    Δτ = options.Δτ
    t0 = options.τ0

    if options.history
        λ_all = zeros(Float64,m,N)  # all Lyapunov exponents
    end
    λ = zeros(Float64,m)         # Lyapunov exponents

    nx = size(ic, 1)
    if m > nx
        @warn "m must be less than or equal to the dimension of the system"
        @info "Setting number of computed Lyapunov exponents to the dimension of system $(nx)"
        λ[nx+1:m] .= NaN
        if options.history
            λ_all[nx+1:m,:] .= NaN
        end
        m = nx
    end

    ujm1 = integrator(range(t0, stop=τ, step=Δτ), ic; kwargs...)[:, end]

    # Initialize the Q matrix
    if options.initialization == :random
        Q = Matrix(LinearAlgebra.qr(randn(nx, m)).Q)     # orthogonal directions with random vectors
    else
        Q = 1.0I(nx)[:,1:m]  # unit orthogonal directions
    end

    prog = Progress(N; desc="Computing Lyapunov exponents... ", color=:blue)
    tj = τ
    for j in 1:N
        uj = integrator(range(tj, stop=tj+T, step=Δt), ujm1; kwargs...)[:,end]

        Threads.@threads for i in 1:m
            u_tjm1 = ujm1 + ϵ * Q[:,i]  # perturb the starting value
            wj_i = integrator(range(tj, stop=tj+T, step=Δt), u_tjm1; kwargs...)[:,end]
            Q[:,i] = (wj_i - uj) / ϵ
        end
        QR = LinearAlgebra.qr(Q)
        Q = Matrix(QR.Q)  # update the Q matrix
        R = QR.R          # obtain the R matrix (upper triangular: expansion/contraction rates)
        posDiag_QR!(Q, R) # make sure the diagonal of R is positive
        Q = Q[:, 1:m]     # truncate Q to the first m columns
        R = R[1:m, 1:m]   # truncate R to the first m rows and columns

        # add to the Lyapunov exponents
        λ[1:m] .+= log.(diag(R))

        if options.history
            λ_all[1:m,j] = λ / j / T
        end

        # update values
        tj += T
        ujm1 = uj

        if options.verbose
            next!(prog)
        end
    end

    if options.history
        return λ / N / T, λ_all
    else
        return λ / N / T
    end

end


"""
    posDiag_QR!(Q::AbstractMatrix, R::AbstractMatrix)

Make sure the diagonal of the R matrix is positive.

# Arguments
- `Q::AbstractMatrix`: orthogonal directions
- `R::AbstractMatrix`: upper triangular matrix

# Returns
- `nothing`
"""
function posDiag_QR!(Q::AbstractMatrix, R::AbstractMatrix)
    @assert size(Q, 2) == size(R, 2) "Q and R must have the same number of columns"

    m = size(Q, 2)
    for i in 1:m
        if R[i,i] < 0
            Q[:,i] = -Q[:,i]
            R[i,:] = -R[i,:]
        end
    end
end


"""
$(SIGNATURES)

Compute the Lyapunov exponents of the full order dynamical system using the Jacobian of the system. 
Refer to [References](#References) for more details.

# Arguments
- `integrator::Function`: integrator for the full/reduced model
- `jacobian::Function`: Jacobian of the system
- `ic::AbstractArray`: initial condition
- `options::LyapunovExponentOptions`: options for the algorithm
- `kwargs...`: keyword arguments for the integrator

# Returns
- `λ::Vector`: the Lyapunov exponents
- `λ_all::Matrix`: all Lyapunov exponents if `options.history` is `true`

# Integrator function format
The integrator function must be in the form of `integrator(tspan, ic)` where `tspan` is the time span to integrate over
and `ic` is the initial condition. The integrator must return the solution at the final time. And the integrator can 
have additional parameters as keyword arguments `kwargs...`.

# Function to generate the Jacobian
The Jacobian function must be in the form of `jacobian(x; kwargs...)` where `x` is the state.
This Jacobian matrix constructs the Linear Tangent Map (LTM) of the system. The Jacobian for a linear-quadratic system 

```math
\\dot{\\mathbf{x}} = \\mathbf{Ax} + \\mathbf{H}(\\mathbf{x} \\otimes \\mathbf{x})
```

is for exmaple

```julia
function jacobian(ops, x)
    A = ops.A
    H = ops.H
    return A + H * kron(1.0I(n), x) + H * kron(x, 1.0I(n))
end
```

# References
- [GitHub code](https://github.com/ni-sha-c/Lyapunov) by `ni-sha-c` 
- [GitHub code](https://github.com/ThomasSavary08/Lyapynov) by `ThomasSavary08`
- P. V. Kuptsov and U. Parlitz, “Theory and computation of covariant Lyapunov vectors,” arXiv, 2011, doi: 10.48550/ARXIV.1105.5228.
"""
function lyapunov_exponent_jacobian(
    integrator::Function,               # integrator for the full/reduced model
    jacobian::Function,                 # Jacobian of the system
    ic::AbstractArray,                  # initial condition
    options::LyapunovExponentOptions;   # options for the algorithm
    kwargs...                           # keyword arguments for the integrator
    )

    # TODO: Remove the timestep variable T since for the Linear Tangent Map (LTM)
    # it does not make sense to use a larger timestep since the LTM is linear and 
    # should evolve with short time steps (i.e. Δt << T).

    # Unpack options
    m = options.m
    τ = options.τ
    T = options.T
    N = options.N
    Δt = options.Δt
    t0 = options.τ0

    if options.history
        λ_all = zeros(Float64,m,N)  # all Lyapunov exponents
    end
    λ = zeros(Float64,m)         # Lyapunov exponents

    nx = size(ic, 1)
    if m > nx
        @warn "m must be less than or equal to the dimension of the system"
        @info "Setting number of computed Lyapunov exponents to the dimension of system $(nx)"
        λ[nx+1:m] .= NaN
        if options.history
            λ_all[nx+1:m,:] .= NaN
        end
        m = nx
    end

    uj = integrator(range(t0, stop=τ, step=Δt), ic; kwargs...)[:, end]

    # Initialize the Q matrix
    if options.initialization == :random
        Q = Matrix(LinearAlgebra.qr(randn(nx, m)).Q)  # orthogonal directions with random vectors
    else
        Q = 1.0I(nx)[:,1:m]  # unit orthogonal directions
    end

    prog = Progress(N; desc="Computing Lyapunov exponents... ", color=:blue)
    tj = τ
    for j in 1:N
        # Compute perturbed states
        Q = options.pert_integrator(jacobian(uj; kwargs...), Q, Δt)

        # Update the state values by integrating the model
        uj = integrator(range(tj, stop=tj+T, step=Δt), uj; kwargs...)[:,end]

        # Orthonormalize the fundamental matrix with the QR decomposition
        QR = LinearAlgebra.qr(Q)
        Q = Matrix(QR.Q)  # update the Q matrix
        R = QR.R          # obtain the R matrix (upper triangular: expansion/contraction rates)
        posDiag_QR!(Q, R) # make sure the diagonal of R is positive
        Q = Q[:, 1:m]     # truncate Q to the first m columns
        R = R[1:m, 1:m]   # truncate R to the first m rows and columns

        # add to the Lyapunov exponents
        λ[1:m] .+= log.(diag(R))

        if options.history
            λ_all[1:m,j] .= λ / j / Δt
        end

        # update time
        tj += T
        if options.verbose
            next!(prog)
        end
    end

    if options.history
        return λ / N / Δt, λ_all
    else
        return λ / N / Δt
    end
end


"""
$(SIGNATURES)

Compute the Lyapunov exponent using either of the two methods:
- `fullmodel`: which integrates the full model and its perturbed states
- `jacobian`: which uses the Jacobian or the Linear Tangent Map (LTM) of the system

# Arguments
- `integrator::Function`: integrator for the full/reduced model
- `ic::AbstractArray`: initial condition
- `options::LyapunovExponentOptions`: options for the algorithm
- `jacobian::Function`: Jacobian of the system
- `kwargs...`: keyword arguments for the integrator

# Returns
- `λ::Vector`: the Lyapunov exponents
- `λ_all::Matrix`: all Lyapunov exponents if `options.history` is `true`
"""
function lyapunov_exponent(
    integrator::Function,               # integrator for the full/reduced model
    ic::AbstractArray,                  # initial condition
    options::LyapunovExponentOptions;   # options for the algorithm
    jacobian::Function,                 # Jacobian of the system
    kwargs...                           # keyword arguments for the integrator
    )
    if options.jacobian
        @assert @isdefined(jacobian) "The Jacobian function must be provided for the Jacobian method"
        return lyapunov_exponent_jacobian(integrator, jacobian, ic, options; kwargs...)
    else
        return lyapunov_exponent_fullmodel(integrator, ic, options; kwargs...)
    end
end


"""
$(SIGNATURES)

Compute the Kaplan-Yorke dimension from the Lyapunov exponents.

# Arguments
- `λs::AbstractVector{<:Real}`: the Lyapunov exponents
- `sorted::Bool`: whether the Lyapunov exponents are sorted in descending order

# Returns
- `Float64`: the Kaplan-Yorke dimension

# Example 
```julia-repl
julia> using LiftAndLearn.ChaosGizmo

julia> CG = LiftAndLearn.ChaosGizmo

julia> lyapunovSpectrum = [0.5, 0.1, -0.2, -0.4]  # Example spectrum

julia> ky = CG.kaplan_yorke_dim(lyapunovSpectrum)

```
"""
function kaplan_yorke_dim(λs::AbstractVector{<:Real}; sorted::Bool=true)
    if !sorted
        λs = sort(vec(λs), rev=true)
    end

    # Find the index where the sum of λ becomes negative
    j = nothing
    tmp = 0
    for (i,λ) in enumerate(λs)
        tmp += λ
        if tmp < 0
            j = i
            break
        end
    end

    if isnothing(j)
        return length(λs)  # if all exponents are non-negative
    elseif j == 1
        return 0   # if all exponents are negative, return 0
    else
        return (j - 1) + sum(λs[1:j-1]) / abs(λs[j])
    end
end

