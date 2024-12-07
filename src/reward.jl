function POMDPs.reward(pomdp::RockSamplePOMDP, s::RSState, a::Int)
    r = 0.0
    # motion costs
    # diagonal motions cost sqrt(2), others 1.0
    if a in [2,4,6,8]
        r += pomdp.step_penalty
    elseif a in [3,5,7,9]
        r += pomdp.step_penalty * sqrt(2)
    end
    # this used to accrue the reward before the state transition,
    # but the transitions are stochastic now
    # if next_position(s, a)[1] > pomdp.map_size[1]
    #     r += pomdp.exit_reward
    #     return r
    # end
    # if we are in the final state - which deterministically leads to the
    # terminal state, reward the completion. Due to the transition function,
    # this should only be awarded once.
    if s == pomdp.final_state
        r += pomdp.exit_reward
        return r
    end
    #if a == BASIC_ACTIONS_DICT[:sample] && in(s.pos, pomdp.rocks_positions) # sample
    if in(s.pos, pomdp.rocks_positions)
        # note you can only accrue this reward once - the transition function
        # assures this is a terminal state for this ... rock
        rock_ind = findfirst(isequal(s.pos), pomdp.rocks_positions) # slow ?
        # if this has already been collected, there is nothing to do.
        # see the transition function!
        if !s.rocks[rock_ind]
            r += pomdp.rocks_rewards[rock_ind]
        end
    end
    if a==1 # using sensor
        r += pomdp.sensor_use_penalty
    end
    return r
end