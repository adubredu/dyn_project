ENV["GUROBI_HOME"]="/home/alphonsus/software/gurobi/gurobi9.5.0_linux64/gurobi950/linux64/"
ENV["GRB_LICENSE_FILE"]="/home/alphonsus/keys/gurobi.lic"


using JuMP 
using Gurobi 
using DataFrames 

cost_and_effectiveness = DataFrame(Vaccine_Type=[:A, :B, :C, :D], 
                           Cost=[3.2, 3.45, 3.5, 3.3],
                           Effectiveness=[.50,.55,.55,.55])
cost_per_vaccine_per_time = DataFrame(Vaccine_Type=[:A, :B, :C, :D],
                           T₀=[2., 2.3, 3., 2.4],
                           T₁=[2.45, 2.6, 2.47, 2.6],
                           T₂=[2.5, 2.8, 2.47, 2.44],
                           T₃=[2.558, 2.745, 2.87, 2.916],
                           T₄=[2.3122, 2.2805, 2.3, 2.6244],
                           T₅=[2.18098, 2.95245, 2.37147, 2.36196 ],
                           T₆=[2.62882, 2.657205, 2.594323, 2.625764],
                           T₇=[1.913, 1.913, 1.913, 1.913])
population = DataFrame(Age_range=["0-5", "6-18", "19-65","65+"],
                           Population=[19200, 54400, 268400, 58000])            
effectiveness_per_population = DataFrame(Age_range=["0-5", "6-18", "19-65","65+"],
                           A=[.75, .50, .50, .50],
                           B=[.70,.65, .65, .66],
                           C=[.60,.60, .65, .60],
                           D=[.65,.65, .65, .65])           
budget_per_time = DataFrame(Time=[:T₀, :T₁, :T₂, :T₃, :T₄, :T₅, :T₆, :T₇ ],
                           Budget=[142850., 122850., 112850., 162850., 172850., 152850., 162850., 122850.])        
                           
function resultant_value(vaccine_type)
    col_ind = findall(x->x==vaccine_type, cost_and_effectiveness[:,names(cost_and_effectiveness)[1]])[1]
    êᵢ = cost_and_effectiveness[:,:Effectiveness][col_ind]
    Σ = sum([e*0.001*n for (e,n) in zip(effectiveness_per_population[:, vaccine_type], population[:,:Population])])
    eᵢ = êᵢ * Σ
    return eᵢ
end

function find_col_index(var, df) 
    ind = findall(x->x==var, df[:,names(df)[1]])[1]
    return ind
end

xs = []
ts = [:T₀, :T₁, :T₂, :T₃, :T₄, :T₅, :T₆, :T₇]
V = [resultant_value(vax) for vax in [:A, :B, :C, :D]]
N = length(cost_and_effectiveness[:,:Vaccine_Type])
init = [0 for i=1:N]


for t in ts 
    C = cost_per_vaccine_per_time[:,t]
    B = budget_per_time[:,:Budget][find_col_index(t, budget_per_time)] 

    tvlp = Model(Gurobi.Optimizer) 

    @variable(tvlp, x[i=1:N] >= 10000, Int, start = init[i])
    @constraint(tvlp, C'x <= B)
    # @constraint(tvlp, x >=)
    @objective(tvlp, Max, V'x)
    optimize!(tvlp)
    init = value.(x)
    push!(xs, init)
    println("Time step ",t," ",init)
end

xs=hcat(xs...)

using PlotlyJS

times = [String(t) for t in ts]

p = plot([
    bar(name="Vaccine A", x=times, y=xs[1,:]),
    bar(name="Vaccine B", x=times, y=xs[2,:]),
    bar(name="Vaccine C", x=times, y=xs[3,:]),
    bar(name="Vaccine D", x=times, y=xs[4,:])
])
relayout!(p, barmode="group")
p