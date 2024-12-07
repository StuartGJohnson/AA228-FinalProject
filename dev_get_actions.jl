using POMDPs
using POMDPXFiles
using RockSample 
using SARSOP # load a  POMDP Solver
using POMDPGifs # to make gifs
using Cairo # for making/saving the gif
using StaticArrays
using Random
using Serialization
using POMDPTools
using Statistics
using LinearAlgebra
using DataFrames
using CSV
using MAT

include("src/RockSample.jl")

pomdp2 = deserialize("pomdp_2cp_1200.jls")
println(length(pomdp2))
policy2 = load_policy(pomdp2, "policy_2cp_1200.out")

# compute the best action if I am in the middle of the map at all three states of discovery
dps = Array{Float64}(undef, length(policy2.alphas))
dps .= 0.0

state1 = Array{Float64}(undef, 401)
state1 .= 0.0
this_state1 = RSState(RSPos(4,4), SVector{2,Bool}([true, false]))
state1[stateindex(pomdp2, this_state1)] = 1.0/2.0
# this_state2 = RSState(RSPos(2,8), SVector{2,Bool}([true, false]))
# state1[stateindex(pomdp2, this_state2)] = 1.0/3.0
this_state3 = RSState(RSPos(6,6), SVector{2,Bool}([true, false]))
state1[stateindex(pomdp2, this_state3)] = 1.0/2.0
for (i, alpha) in enumerate(policy2.alphas)
    dps[i] = dot(alpha,state1)
end

best_action = policy2.action_map[argmax(dps)]
