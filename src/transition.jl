struct RSPosStoch
    pos::RSPos
    prob::Float64
end

function POMDPs.transition(pomdp::RockSamplePOMDP{K}, s::RSState{K}, a::Int) where K
    if isterminal(pomdp, s)
        return Deterministic(pomdp.terminal_state)
    end
    if s==pomdp.final_state
        return Deterministic(pomdp.terminal_state)
    end
    # if we are at a rock, transition the rock state to visited. This is
    # essential to prevent repeat reward accrual.
    if in(s.pos, pomdp.rocks_positions)
        rock_ind = findfirst(isequal(s.pos), pomdp.rocks_positions) # slow ?
        # set the new rock to true (visited)
        new_rocks = MVector{K, Bool}(undef)
        for r=1:K
            new_rocks[r] = r == rock_ind ? true : s.rocks[r]
        end
        new_rocks = SVector(new_rocks)
    else 
        new_rocks = s.rocks
    end
    # this will return a distribution of states, generally,
    # so we need to cook up a SparseCat
    new_pos = next_position(pomdp::RockSamplePOMDP{K}, s, a)
    # now let's combine the deterministic rock state
    # evolution with the stochastic position states.
    # in other words, repack into a SparseCat over states.
    # when I clamp states to the grid domain, I will
    # sometimes get duplications of states
    probs = normalize!(ones(length(new_pos)), 1)
    states = Vector{RSState{K}}(undef, length(new_pos))
    # we only have one initial state - no distribution
    for (i,rss) in enumerate(new_pos)
        # clamp state
        this_pos = clamp_state(pomdp, rss.pos)
        probs[i] = rss.prob
        states[i] = RSState{K}(this_pos, new_rocks)
    end
    # states can fold back into the grid domain, so...
    # repack these into unique states, summing probabilities
    unique_states = unique(states)
    unique_probs = ones(length(unique_states))
    for (i,ust) in enumerate(unique_states)
        unique_probs[i] = sum(probs[findall(==(ust),states)])
    end
    unique_probs = normalize!(unique_probs, 1)
    return SparseCat(unique_states, unique_probs)
end

function clamp_state(pomdp::RockSamplePOMDP{K}, s::RSPos) where K
    return RSPos(clamp(s[1], 1, pomdp.map_size[1]), 
                        clamp(s[2], 1, pomdp.map_size[2]))
end

function next_position(pomdp::RockSamplePOMDP{K}, s::RSState, a::Int) where K
    if a == 1
        # robot samples - no motion
        new_positions = Vector{RSPosStoch}(undef, 1)
        new_positions[1] = RSPosStoch(s.pos, 1.0)
    elseif a <= N_BASIC_ACTIONS
        # the robot may move in a few directions
        # here we return the core possible positions and
        # the corresponding probabilities
        new_actions = circ_neighbors(a-1) .+ 1
        # positions and probabilities
        new_positions = Vector{RSPosStoch}(undef, length(new_actions))
        # left, center and right
        new_positions[1] = RSPosStoch(s.pos + ACTION_DIRS[new_actions[1]], (1.0-pomdp.chosen_trajectory_prob)/2.0)
        new_positions[2] = RSPosStoch(s.pos + ACTION_DIRS[new_actions[2]], pomdp.chosen_trajectory_prob)
        new_positions[3] = RSPosStoch(s.pos + ACTION_DIRS[new_actions[3]], (1.0-pomdp.chosen_trajectory_prob)/2.0)
    end
    return new_positions
end

function circ_neighbors(a::Int)
    # This assumes a is in the range of 1:8
    # so don't forget to adjust
    num_dir = 8
    left = mod(a - 2, num_dir) + 1
    center = a
    right = mod(a , num_dir) + 1
    return [left, center, right]
end