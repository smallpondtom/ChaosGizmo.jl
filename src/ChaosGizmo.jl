"""
    Gizmos to conduct chaos analysis mainly for large-scale dynamical systems.
"""
module ChaosGizmo

using DocStringExtensions
using LinearAlgebra
using Parameters
using ProgressMeter
using SparseArrays

# using UniqueKronecker: extractF, extractH
# import ..LiftAndLearn: Operators

include("integrators.jl")
include("LyapunovExponent.jl")

end
