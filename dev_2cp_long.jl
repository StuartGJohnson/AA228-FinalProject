using POMDPs
using RockSample 
using SARSOP # load a  POMDP Solver
using POMDPGifs # to make gifs
using Cairo # for making/saving the gif
using StaticArrays
using Random
using Serialization

pomdp = RockSamplePOMDP(map_size = (10,10),
                        rocks_positions = @SVector([RSPos(7,3), RSPos(3,7),]),
                        rocks_rewards = @SVector([25.0, 20.0]),
                        position_noise_variance = 0.5,
                        chosen_trajectory_prob = 0.7,
                        discount_factor = 0.8, 
                        init_pos = RSPos(10,10),
                        final_pos = RSPos(9,10),
                        step_penalty = -1.0,
                        exit_reward = 20.0,
                        sensor_use_penalty = -1.0
                        )

serialize("pomdp_2cp_1200.jls", pomdp)

solver = SARSOPSolver(timeout=1200)

println(length(pomdp))

# capture the SARSOP output
# Capture output in a file
report_file = "sarsop_report_2cp_1200.txt"
open(report_file, "w") do file
    redirect_stdout(file) do
        policy = solve(solver, pomdp)  # Solve the POMDP
    end
end

mv("policy.out", "policy_2cp_1200.out", force=true)

# for j in 1:5
#     Random.seed!(j)
#     sim = GifSimulator(filename="test_2cp_240_$j.gif", max_steps=100)
#     simulate(sim, pomdp, policy)
# end