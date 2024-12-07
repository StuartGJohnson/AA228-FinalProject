const N_BASIC_ACTIONS = 9
const BASIC_ACTIONS_DICT = Dict(:sample => 1,
                                :north => 2,
                                :northeast => 3, 
                                :east => 4,
                                :southeast => 5,
                                :south => 6,
                                :southwest => 7,
                                :west => 8,
                                :northwest => 9,               
                                )

 # lets order this in a circular fashion                               
const ACTION_DIRS = (RSPos(0,0),
                    RSPos(0,1),
                    RSPos(1,1),
                    RSPos(1,0),
                    RSPos(1,-1),   
                    RSPos(0,-1),
                    RSPos(-1,-1),
                    RSPos(-1,0),
                    RSPos(-1,1),
                    )

#POMDPs.actions(pomdp::RockSamplePOMDP{K}) where K = 1:N_BASIC_ACTIONS+K
POMDPs.actions(pomdp::RockSamplePOMDP{K}) where K = 1:N_BASIC_ACTIONS
POMDPs.actionindex(pomdp::RockSamplePOMDP, a::Int) = a

function POMDPs.actions(pomdp::RockSamplePOMDP{K}, s::RSState) where K
    return actions(pomdp)
    # this is no longer applicable. the sampling refers to the agent, not the rocks.
    # if in(s.pos, pomdp.rocks_positions) # slow? pomdp.rock_pos is a vec 
    #     return actions(pomdp)
    # else
    #     # sample not available 
    #     return 2:N_BASIC_ACTIONS
    # end
end

function POMDPs.actions(pomdp::RockSamplePOMDP, b)
    # All states in a belief should have the same position, which is what the valid action space depends on
    state = rand(Random.GLOBAL_RNG, b) 
    return actions(pomdp, state)
end
