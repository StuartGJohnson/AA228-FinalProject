#using Distributions

# remember the extra state for no observation!
POMDPs.observations(pomdp::RockSamplePOMDP) = 1:((pomdp.map_size[1]*pomdp.map_size[2])+1)
POMDPs.obsindex(pomdp::RockSamplePOMDP, o::Int) = o

function POMDPs.observation(pomdp::RockSamplePOMDP, a::Int, s::RSState)
    obs_space = POMDPs.observations(pomdp)
    num_obs = length(obs_space)
    probs = zeros(num_obs)
    linear_indices = LinearIndices((pomdp.map_size[1], pomdp.map_size[2]))

    if s.pos in pomdp.known_states
        # return the observation corresponding to the state only.
        # I am never confused about being in one of these states.
        probs[linear_indices[s.pos...]] = 1.0
    elseif a != 1
        # no observation, use the non-observation observation
        probs[num_obs] = 1.0
        #nx, ny = pomdp.map_size
        #s = CartesianIndices((nx, ny, rocks_dim...))[si]
        #return SparseCat((1,2,3), (0.0,0.0,1.0)) # for type stability
    else
        nx, ny = pomdp.map_size
        s_ind = CartesianIndices((nx, ny))
        s2 = pomdp.position_noise_variance
        dist = MvNormal([0.0, 0.0],Diagonal([s2, s2]))
        for i in 1:(num_obs-1)
            x = Float64.(collect(Tuple(s_ind[i]) .- s.pos))
            # println("x[$i]: $x, Valid: ", all(isfinite, x))
            # if length(x) == 2
            #     probs[i] = pdf(dist, x)
            # else
            #     println("Invalid x at index $i: $x")
            # end
            #println("Type of x: ", typeof(x))
            #println("Type of x elements: ", typeof(x[1]))
            probs[i] = pdf(dist, x)
            #println(probs[i])
        end
        # zero out the observations corresponding to known states
        for ks in pomdp.known_states
            probs[linear_indices[ks...]] = 0.0
        end
        # scale, normalize
        probs ./= maximum(probs)
        # make this a uniform dist within FWHM
        #probs[probs.>0.5] .= 1.0
        #probs[probs.<=0.5] .= 0.0
        probs = round.(probs,digits=3)
        probs ./= sum(probs)
        probs[end] = 1.0 - sum(probs)
        #println(sum(probs))
        # we will come back to this
        #rock_ind = a - N_BASIC_ACTIONS 
        #rock_pos = pomdp.rocks_positions[rock_ind]
        #rock_diff = pomdp.rocks_difficulty[rock_ind]
        # rock_diff is essentially how near I need to be to visit and validate
        # a rock. The difficulty of the rock controls the transition of
        # this sigmoid.
        #dist = norm(rock_pos - s.pos)
        #prob_find = 2.0/(1.0 + exp(-dist/rock_diff))
        #rock_state = s.rocks[rock_ind]
        #if rock_state
        #    return SparseCat((1,2,3), (prob_find, 1.0 - prob_find, 0.0))
        #else
        #    return SparseCat((1,2,3), (0.05, 0.95, 0.0))
        #end
    end

    return SparseCat(Tuple(1:length(probs)), probs)

end