using Mimi
using OptiMimi
using Test

# From http://www.purplemath.com/modules/linprog3.htm

# You need to buy some filing cabinets. You know that Cabinet X costs
# $10 per unit, requires six square feet of floor space, and holds eight
# cubic feet of files. Cabinet Y costs $20 per unit, requires eight
# square feet of floor space, and holds twelve cubic feet of files. You
# have been given $140 for this purchase, though you don't have to spend
# that much. The office has room for no more than 72 square feet of
# cabinets. How many of which model should you buy, in order to maximize
# storage volume?

# Construct the Cabinets component
@defcomp Cabinets begin
    office = Index()

    # Two kinds of cabinet: model X and Y
    x = Parameter(index=[time, office])
    y = Parameter(index=[time, office])

    cost = Variable(index=[time, office])
    space = Variable(index=[time, office])
    volume = Variable(index=[time, office])
end

# Define all gradients
grad_cabinets_cost_x(m::Model) = roomdiagonal(m, :Cabinets, :cost, :x, (tt, ii) -> 10)
grad_cabinets_cost_y(m::Model) = roomdiagonal(m, :Cabinets, :cost, :y, (tt, ii) -> 20)
grad_cabinets_space_x(m::Model) = roomdiagonal(m, :Cabinets, :space, :x, (tt, ii) -> 6)
grad_cabinets_space_y(m::Model) = roomdiagonal(m, :Cabinets, :space, :y, (tt, ii) -> 8)
grad_cabinets_volume_x(m::Model) = roomdiagonal(m, :Cabinets, :volume, :x, (tt, ii) -> 8)
grad_cabinets_volume_y(m::Model) = roomdiagonal(m, :Cabinets, :volume, :y, (tt, ii) -> 12)

# And the constraints
constraintoffset_cabinets_cost(m::Model) = hallsingle(m, :Cabinets, :cost, (tt, ii) -> 140)
constraintoffset_cabinets_space(m::Model) = hallsingle(m, :Cabinets, :space, (tt, ii) -> 72)

# Create the model
m = Model()
set_dimension!(m, :time, [1])
set_dimension!(m, :office, collect(1:2))

cabinets = add_comp!(m, Cabinets)
cabinets[:x] = zeros(1, 2)
cabinets[:y] = zeros(1, 2)

# Create the constraint matrix
paramcomps = [:Cabinets, :Cabinets]
parameters = [:x, :y]
constcomps = [:Cabinets, :Cabinets]
constraints = [:cost, :space]

house = LinearProgrammingHouse(m, paramcomps, parameters, constcomps, constraints);

setobjective!(house, varsum(grad_cabinets_volume_x(m)))
setobjective!(house, varsum(grad_cabinets_volume_y(m)))

setconstraint!(house, grad_cabinets_cost_x(m))
setconstraint!(house, grad_cabinets_cost_y(m))
setconstraintoffset!(house, constraintoffset_cabinets_cost(m))

setconstraint!(house, grad_cabinets_space_x(m))
setconstraint!(house, grad_cabinets_space_y(m))
setconstraintoffset!(house, constraintoffset_cabinets_space(m))

# Solve the problem
@time sol = houseoptimize(house)
println(sol.sol)

@test sol.sol[1] ≈ 8.0
@test sol.sol[2] ≈ 8.0
@test sol.sol[3] ≈ 3.0
@test sol.sol[4] ≈ 3.0

# 100 cubic feet by buying eight of model X and three of model Y.

# What are the constraining elements?
println(constraining(house, sol.sol))
