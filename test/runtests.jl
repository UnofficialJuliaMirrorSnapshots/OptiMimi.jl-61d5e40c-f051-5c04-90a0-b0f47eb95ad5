using Mimi
using OptiMimi
using Test

using ForwardDiff

include("testlp.jl")

# Differentiation-free optimization
# Create quadratic component
@defcomp quad1 begin
    regions = Index()

    # The x-value of the maximum of the quadratic
    maximum = Parameter(index=[regions])

    # The x-value to evaluate the quadratic
    input = Parameter(index=[regions])

    # The y-value of the quadratic at the x-value
    value = Variable(index=[regions])

    function run_timestep(p, v, d, t)
        v.value[:] = -(p.input - p.maximum).^2
    end
end

# Prepare model
model1 = Model()
set_dimension!(model1, :time, 1)
set_dimension!(model1, :regions, 2)
add_comp!(model1, quad1)
set_param!(model1, :quad1, :maximum, [2., 10.])
set_param!(model1, :quad1, :input, [0., 0.])

objective1(model::Model) = sum(model[:quad1, :value])

optprob = problem(model1, [:quad1], [:input], [0.], [100.0], objective1)
(maxf, maxx) = solution(optprob, () -> [0., 0.])

@test maxf ≈ 0 atol=0.01
@test maxx[1] ≈ 2 atol=0.01
@test maxx[2] ≈ 10 atol=0.01

# Automatic differentiation

# Create quadratic component
@defcomp quad2 begin
    regions = Index()

    # The x-value of the maximum of the quadratic
    maximum = Parameter(index=[regions])

    # The x-value to evaluate the quadratic
    input = Parameter(index=[regions])

    # The y-value of the quadratic at the x-value
    value = Variable(index=[regions])

    function run_timestep(p, v, d, t)
        v.value[:] = -(p.input - p.maximum).^2
    end
end

# Prepare model
model2 = Model(Number)
set_dimension!(model2, :time, 1)
set_dimension!(model2, :regions, 2)
add_comp!(model2, quad2)
set_param!(model2, :quad2, :maximum, convert(Array{Number,1}, [2., 10.]))
set_param!(model2, :quad2, :input, convert(Array{Number,1}, [0., 0.]))

objective2(model::Model) = sum(model[:quad2, :value])

# Test the translation to a simple objective function
uo = unaryobjective(model2, [:quad2], [:input], objective2)
guo(xx) = ForwardDiff.gradient(uo, xx)
guos = guo([0., 0.])
@test guos[1] ≈ 4 atol=0.01
@test guos[2] ≈ 20 atol=0.01

# Optimize
optprob = problem(model2, [:quad2], [:input], [0.], [100.0], objective2)
(maxf, maxx) = solution(optprob, () -> [0., 0.])


@test maxf ≈ 0 atol=0.01
@test maxx[1] ≈ 2 atol=0.01
@test maxx[2] ≈ 10 atol=0.01

include("test_dupover.jl")
