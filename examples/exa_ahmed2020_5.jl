module Example_Ahmed2020_5

# Automated and Sound Synthesis of Lyapunov Functions with SMT Solvers

# Not working yet ...

using LinearAlgebra
using Random
Random.seed!(0)
using DynamicPolynomials
using Plots
using DifferentialEquations
using CDDLib
using SumOfSquares
using MosekTools

include("../utils.jl")

var, = @polyvar x[1:6]
flow = [
    -x[1]^2 - 4 * x[2]^3 - 6 * x[3] * x[4],
    -x[1] - x[2] + x[5]^3,
    x[1] * x[4] - x[3] + x[4] * x[6],
    x[1] * x[3] + x[3] * x[6] - x[4]^3,
    -2 * x[2]^3 - x[5] + x[6],
    -3 * x[3] * x[4] - x[5]^3 - x[6],
]
display(flow)
rad = 0.5
dom_init = @set x' * x ≤ rad^2

nstep = 5
dt = 1.0
np = 5
vals = generate_vals(np, rad, dt, nstep, var, flow)

include("../../src/DualConeRefinementSafety.jl")
const DCR = DualConeRefinementSafety

F = DCR.Field(var, flow)
points = [DCR.Point(var, val) for val in vals]
funcs = [1, x[1]^2, x[2]^2, x[3]^2, x[4]^2, x[5]^2, x[6]^2]
display(funcs)
λ = 1.0
ϵ = 1e-2
hc = DCR.hcone_from_points(funcs, F, λ, ϵ, points)
display(length(hc.halfspaces))

vc = DCR.vcone_from_hcone(hc, () -> CDDLib.Library())
display(length(vc.rays))

δ = 1e-4
success = DCR.narrow_vcone!(vc, dom_init, F, λ, ϵ, δ, Inf, solver,
                            callback_func=callback_func)
display(success)
display(vc.rays)

model = solver()
r = @variable(model)
dom = DCR.sos_domain_from_vcone(vc)
@constraint(model, x' * x ≤ r, domain=dom)
@objective(model, Min, r)
optimize!(model)
@assert primal_status(model) == FEASIBLE_POINT
display(sqrt(value(r)))

end # module