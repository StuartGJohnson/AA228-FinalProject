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

pomdp2 = deserialize("pomdp_2cp_1200.jls")
println(length(pomdp2))
policy2 = load_policy(pomdp2, "policy_2cp_1200.out")

num_gifs = 10
vec_samples = []
vec_steps = []
vec_reward = []
vec_belief = []
array_hist = Array{Int}(undef,pomdp2.map_size[1],pomdp2.map_size[2])
array_hist .= 0
tmp_belief = []
# this loop produces raw data, which is stored to a data frame for retrieval and
# computation of stats
for j in 1:10
    # only produce gifs for a small fraction of these sims
    # random seed defines the sim
    Random.seed!(j)
    if j <= num_gifs
        sim = GifSimulator(filename="policy_2cp_1200x2_$j.gif", max_steps=40)
        sim_result = simulate(sim, pomdp2, policy2)
    end
    sim2 = StepSimulator("s,a,r,sp,b")
    num_samples = 0
    num_steps = 0
    sample_dist = []
    belief_dist = []
    reward = 0.0
    Random.seed!(j)
    for (s,a,r,sp,b) in simulate(sim2, pomdp2, policy2)
        num_steps += 1
        reward += r
        if a==1 && s.pos != pomdp2.final_pos
            num_samples += 1
            array_hist[s.pos...] += 1
            # find minimum distance to a control point 
            dcp = pomdp2.rocks_positions .- Ref(s.pos)
            push!(sample_dist,minimum([norm(d) for d in dcp]))
            push!(belief_dist,sum((b.b/maximum(b.b)).>0.5))
        end
    end
    println("steps: ", num_steps, " samples: ", num_samples, " dist: ", num_samples > 0 ? median(sample_dist) : 0, " reward: ", reward)
    push!(vec_samples, num_samples)
    push!(vec_steps, num_steps)
    push!(vec_reward, reward)
    push!(vec_belief, num_samples > 0 ? median(belief_dist) : 0)
end

matwrite("policy_2cp_1200x2_hist.mat", Dict("array_hist" => array_hist))
df = DataFrame(mapchecks=vec_samples, steps=vec_steps, reward=vec_reward, belief=vec_belief)
CSV.write("policy_2cp_1200x2_stats.csv", df)