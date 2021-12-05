ENV["GUROBI_HOME"]="/home/alphonsus/software/gurobi/gurobi9.5.0_linux64/gurobi950/linux64/"
ENV["GRB_LICENSE_FILE"]="/home/alphonsus/keys/gurobi.lic"


using JuMP 
using Gurobi 
using DataFrames 

cost_and_effectiveness = DataFrame(Vaccine_Type=[:A, :B, :C, :D], 
                           Cost=[2.0, 2.3, 3.0, 2.4],
                           Effectiveness=[.50,.50,.50,.50])
cost_per_vaccine_per_time = DataFrame(Vaccine_Type=[:A, :B, :C, :D],
                           T₀=[2., 2.3, 3., 2.4],
                           T₁=[1.8, 2.07, 2.7, 2.16],
                           T₂=[1.62, 1.863, 2.43, 1.944],
                           T₃=[1.458, 4.6767, 2.817, 1.7496],
                           T₄=[1.3122, 1.50903, 1.9683, 1.57464],
                           T₅=[1.18098, 1.358127, 1.77147, 1.417176 ],
                           T₆=[1.062882, 1.2223143, 1.594323, 1.2754584],
                           T₇=[0.9565938, 1.1, 1.4348907, 1.1479])
population = DataFrame(Age_range=["0-5", "6-18", "19-65","65+"],
                           Population=[19200/8, 54400/8, 268400/8, 58000/8])            
effectiveness_per_population = DataFrame(Age_range=["0-5", "6-18", "19-65","65+"],
                           A=[.50, .50, .50, .50],
                           B=[.50,.50, .50, .50],
                           C=[.50,.50, .50, .50],
                           D=[.50,.50, .50, .50])           
budget_per_time = DataFrame(Time=[:T₀, :T₁, :T₂, :T₃, :T₄, :T₅, :T₆, :T₇ ],
                           Budget=[60000., 60000., 60000., 60000., 60000., 60000., 60000., 60000.])        
                           
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

    @variable(tvlp, x[i=1:N] , Int)
    @constraint(tvlp, C'x <= B)
    @constraint(tvlp, x .>= 0)
    @objective(tvlp, Max, V'x)
    optimize!(tvlp)
    # init = value.(x)
    push!(xs, value.(x))
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