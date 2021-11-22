using JuMP
using GLPK
using DataFrames

cost_effective = DataFrame(Vaccine_Type=[:A, :B, :C, :D], 
                           Cost=[2., 5., 3., 4.],
                           Effectiveness=[50.,70.,60.,80])


