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
                        rocks_rewards = @SVector([20.0, 25.0]),
                        position_noise_variance = 0.5,
                        chosen_trajectory_prob = 0.7,
                        discount_factor = 0.8, 
                        init_pos = RSPos(10,10),
                        final_pos = RSPos(9,10),
                        step_penalty = -2.0,
                        exit_reward = 20.0,
                        sensor_use_penalty = 0.0
                        )

serialize("pomdp_def.jls", pomdp)