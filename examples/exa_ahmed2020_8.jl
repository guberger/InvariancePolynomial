module Example_Ahmed2020_8

# Automated and Sound Synthesis of Lyapunov Functions with SMT Solvers

using LinearAlgebra
using Random
Random.seed!(0)
using DynamicPolynomials
using Plots
using DifferentialEquations
using CDDLib
using SumOfSquares
using MosekTools

include("utils.jl")

vars, = @polyvar x[1:2]
f = [
    -x[1] - 1.5 * x[1]^2 * x[2]^3,
    -x[2]^3 + 0.5 * x[1]^3 * x[2]^2,
]
display(f)
rad = 2
funcs_init = [x' * x - rad^2]

x1s_ = range(-4, 4, length=10)
x2s_ = range(-4, 4, length=10)
xs = collect(Iterators.product(x1s_, x2s_))[:]
x1s = getindex.(xs, 1)
x2s = getindex.(xs, 2)
dxs = [[fi(vars=>x) for fi in f] for x in xs]
nx = maximum(dx -> norm(dx), dxs)
dxs1 = getindex.(dxs, 1) * 0.4 / nx
dxs2 = getindex.(dxs, 2) * 0.4 / nx
plt = plot(xlabel="x1", ylabel="x2", aspect_ratio=:equal)
quiver!(x1s, x2s, quiver=(dxs1, dxs2))

x1s_ = range(-4, 4, length=20)
x2s_ = range(-4, 4, length=20)
Fplot_init(x1, x2) = maximum(g(vars=>[x1, x2]) for g in funcs_init)
z = @. Fplot_init(x1s_', x2s_)
contour!(x1s_, x2s_, z, levels=[0])

nstep = 5
dt = 1.0
np = 10
points = generate_points(np, rad, dt, nstep, vars, f)

scatter!(getindex.(points, 1), getindex.(points, 2), label="")

display(plt)

include("../src/DualConeRefinementSafety.jl")
const DCR = DualConeRefinementSafety

tmp = DCR.Template(vars, [1, x[1]^2, x[2]^2])
λ = 1.0
ϵ = 1e-2
hc = DCR.hcone_from_points(tmp, f, λ, ϵ, points)
display(length(hc.halfspaces))

vc = DCR.vcone_from_hcone(hc, () -> CDDLib.Library())
display(length(vc.vertices))

ϵ = 1e-2
δ = 1e-4
λ = 1.0
success = DCR.narrow_vcone!(vc, funcs_init, f, λ, ϵ, δ, Inf, solver,
                            callback_func=callback_func)
display(success)

Fplot_vc(x1, x2) = begin
    gxs = [g(vars=>[x1, x2]) for g in vc.tmp.funcs]
    maximum(c -> dot(c, gxs), vc.vertices)
end
z = @. Fplot_vc(x1s_', x2s_)
display(minimum(z))
contour!(x1s_, x2s_, z, levels=[0], color=:green, lw=2)

display(plt)

end # module