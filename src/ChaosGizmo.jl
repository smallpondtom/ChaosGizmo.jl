"""
    Gizmos to conduct chaos analysis mainly for large-scale dynamical systems.
"""
module ChaosGizmo

using DocStringExtensions
using LinearAlgebra
using Parameters
using SparseArrays

import ..LiftAndLearn: AbstractModel, Operators, extractF, extractH

include("integrators.jl")
include("LyapunovExponent.jl")

end
