using POMDPs
using RockSample 
using SARSOP # load a  POMDP Solver
using POMDPGifs # to make gifs
using Cairo # for making/saving the gif
using StaticArrays
using Random

pomdp = RockSamplePOMDP(map_size = (10,10),
                        rocks_positions = @SVector([RSPos(7,3), RSPos(3,7),]),
                        rocks_rewards = @SVector([25.0, 20.0]),
                        position_noise_variance = 0.5,
                        chosen_trajectory_prob = 1.0,
                        discount_factor = 0.99, 
                        init_pos = RSPos(10,10),
                        final_pos = RSPos(9,10),
                        step_penalty = -1.0,
                        exit_reward = 20.0,
                        sensor_use_penalty = -100.0
                        )

solver = SARSOPSolver(precision=0.1)

println(length(pomdp))

policy = solve(solver, pomdp)

for j in 1:5
    Random.seed!(j)
    sim = GifSimulator(filename="test_ref$j.gif", max_steps=30)
    simulate(sim, pomdp, policy)
end