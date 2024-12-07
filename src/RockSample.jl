module RockSample

using LinearAlgebra
using POMDPs
using POMDPTools
using StaticArrays
using Parameters
using Random
using Compose
using Combinatorics
using DiscreteValueIteration
using ParticleFilters           # used in heuristics
using Distributions

export
    RockSamplePOMDP,
    RSPos,
    RSState,
    RSExit,
    RSExitSolver,
    RSMDPSolver,
    RSQMDPSolver

const RSPos = SVector{2, Int}

"""
    RSState{K}
Represents the state in a RockSamplePOMDP problem. 
`K` is an integer representing the number of rocks

# Fields
- `pos::RPos` position of the robot
- `rocks::SVector{K, Bool}` the status of the rocks (false=notVisited, true=Visited)
"""
struct RSState{K}
    pos::RSPos
    rocks::SVector{K, Bool}
end

@with_kw struct RockSamplePOMDP{K, N} <: POMDP{RSState{K}, Int, Int}
    map_size::Tuple{Int, Int} = (5,5)
    rocks_positions::SVector{K,RSPos} = @SVector([(6,6), (3,3), (4,4)])
    rocks_rewards::SVector{K} = @SVector([100,50,10])
    init_pos::RSPos = RSPos(1,1)
    final_pos::RSPos = RSPos(10,10)
    position_noise_variance::Float64 = 5.0
    # the chosen direction (if a move) will
    # actually happen with this prob. The remaining
    # prob is split between the two neighboring
    # directions.
    chosen_trajectory_prob::Float64 = 0.7
    step_penalty::Float64 = 0.
    sensor_use_penalty::Float64 = 0.
    exit_reward::Float64 = 10.
    # hmm, what should be the rock states in the terminal state?
    # todo: why was this a vector of falses for rock state before?
    # this is the state that leads to the terminal state
    final_state::RSState{K} = RSState(RSPos(final_pos),
                                        SVector{length(rocks_positions),Bool}(trues(length(rocks_positions))))
    # this needs to be "outside" the grid
    terminal_state::RSState{K} = RSState(RSPos(-1, -1),
                                         SVector{length(rocks_positions),Bool}(trues(length(rocks_positions))))
    # Some special indices for quickly retrieving the stateindex of any state
    indices::Vector{Int} = cumprod([map_size[1], map_size[2], fill(2, length(rocks_positions))...][1:end-1])
    discount_factor::Float64 = 0.9
    known_states::SVector{N,RSPos} = SVector((rocks_positions..., final_pos, init_pos))
end

# function RockSamplePOMDP(; K::Int = 3, map_size = (5, 5),
#     rocks_positions = @SVector [RSPos(6, 6), RSPos(3, 3), RSPos(4, 4)],
#     rocks_rewards = @SVector [100, 50, 10],
#     init_pos = RSPos(1, 1), final_pos = RSPos(10, 10),
#     position_noise_variance = 5.0, chosen_trajectory_prob = 0.7,
#     step_penalty = 0.0, sensor_use_penalty = 0.0,
#     exit_reward = 10.0, discount_factor = 0.9)
# # Compute dependent fields
# N = length(rocks_positions) + 2
# known_states = SVector((rocks_positions..., final_pos, init_pos))
# final_state = RSState(RSPos(final_pos), SVector{K, Bool}(trues(K)))
# terminal_state = RSState(RSPos(-1, -1), SVector{K, Bool}(trues(K)))

# return RockSamplePOMDP{K, N}(map_size, rocks_positions, rocks_rewards, init_pos,
#             final_pos, position_noise_variance, chosen_trajectory_prob,
#             step_penalty, sensor_use_penalty, exit_reward,
#             discount_factor, known_states, final_state, terminal_state)
# end

#to handle the case where rocks_positions is not a StaticArray
# function RockSamplePOMDP(map_size,
#                          rocks_positions,
#                          args...
#                         )

#     k = length(rocks_positions)
#     return RockSamplePOMDP{k}(map_size,
#                               SVector{k,RSPos}(rocks_positions),
#                               args...
#                              )
# end

# Generate a random instance of RockSample(n,m) with a n×n square map and m rocks
# RockSamplePOMDP(map_size::Int, rocknum::Int, rng::AbstractRNG=Random.GLOBAL_RNG) = RockSamplePOMDP((map_size,map_size), rocknum, rng)

# Generate a random instance of RockSample with a n×m map and l rocks
# function RockSamplePOMDP(map_size::Tuple{Int, Int}, rocknum::Int, rng::AbstractRNG=Random.GLOBAL_RNG)
#     possible_ps = [(i, j) for i in 1:map_size[1], j in 1:map_size[2]]
#     selected = unique(rand(rng, possible_ps, rocknum))
#     while length(selected) != rocknum
#         push!(selected, rand(rng, possible_ps))
#         selected = unique!(selected)
#     end
#     return RockSamplePOMDP(map_size=map_size, rocks_positions=selected)
# end

# transform a Rocksample state to a vector 
function POMDPs.convert_s(T::Type{<:AbstractArray}, s::RSState, m::RockSamplePOMDP)
    return convert(T, vcat(s.pos, s.rocks))
end

# transform a vector to a RSState
function POMDPs.convert_s(T::Type{RSState}, v::AbstractArray, m::RockSamplePOMDP)
    return RSState(RSPos(v[1], v[2]), SVector{length(v)-2,Bool}(v[i] for i = 3:length(v)))
end


# To handle the case where the `rocks_positions` is specified
# RockSamplePOMDP(map_size::Tuple{Int, Int}, rocks_positions::AbstractVector) = RockSamplePOMDP(map_size=map_size, rocks_positions=rocks_positions)

POMDPs.isterminal(pomdp::RockSamplePOMDP, s::RSState) = s == pomdp.terminal_state
POMDPs.discount(pomdp::RockSamplePOMDP) = pomdp.discount_factor

include("states.jl")
include("actions.jl")
include("transition.jl")
include("observations.jl")
include("reward.jl")
include("visualization.jl")
include("heuristics.jl")

end # module
