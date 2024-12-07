function POMDPTools.render(pomdp::RockSamplePOMDP, step;
    viz_rock_state=true,
    viz_belief=true,
    viz_obs=true,
    pre_act_text=""
)
    nx, ny = pomdp.map_size[1], pomdp.map_size[2]+1
    cells = []
    if viz_obs
        obs = getfield(observation(pomdp, step.a, step.s),:probs)
        #println(step.t," ", maximum(obs[1:(length(obs)-1)]))
        #println(sum(obs))
        #println(maximum(obs))
        obs_scale = maximum(obs)
        linear_indices = LinearIndices((nx, ny-1))
        for x in 1:nx, y in 1:ny-1
            linear_index = linear_indices[x, y]
            obs_value = obs[linear_index] / obs_scale
            #gray_value = round(Int, obs_value * 255)
            # this is actually alpha (opacity)
            red_value = round(Int, obs_value * 1.0 * 255)
            hex_red = "#0000FF"
            # hex_gray = string("#", lpad(string(gray_value, base=16), 2, '0'),
            #             lpad(string(gray_value, base=16), 2, '0'),
            #             lpad(string(gray_value, base=16), 2, '0'))
            rgba_red = string(hex_red, lpad(string(red_value, base=16), 2, '0'))
            ctx = cell_ctx((x, y), (nx, ny))
            #cell = compose(ctx, rectangle(), fill(hex_gray))
            cell = compose(ctx, rectangle(), fill(rgba_red))
            push!(cells, cell)
        end
    end

    if viz_belief
        # this is the current position belief. Note that this 
        # and observation can possibly be viewed at the same time
        # given proper alpha settings. First cut is just like the observation,
        # so they probably are not well visualized together - yet.
        b = get(step, :b, nothing)
        position_beliefs = zeros(Float64, (nx)*(ny-1))
        linear_indices = LinearIndices((nx, ny-1))
        for (sᵢ, bᵢ) in weighted_iterator(b)
            # don't account for terminal state belief (at -1,-1)
            if sᵢ.pos[1] > 0 
                position_beliefs[linear_indices[sᵢ.pos...]] += bᵢ
            end
        end
        b_scale = maximum(position_beliefs)
        for x in 1:nx, y in 1:ny-1
            linear_index = linear_indices[x, y]
            obs_value = position_beliefs[linear_index] / b_scale
            gray_value = round(Int, obs_value * 255)
            #color = get(ColorSchemes.viridis, obs_value)
            #gray_color = "gray($gray_value)"
            hex_gray = string("#", lpad(string(gray_value, base=16), 2, '0'),
                        lpad(string(gray_value, base=16), 2, '0'),
                        lpad(string(gray_value, base=16), 2, '0'))
            ctx = cell_ctx((x, y), (nx, ny))
            cell = compose(ctx, rectangle(), fill(hex_gray))
            push!(cells, cell)
        end
    end
    grid = compose(context(), linewidth(0.5mm), stroke("gray"), cells...)
    outline = compose(context(), linewidth(1mm), rectangle())

    rocks = []
    for (i, (rx, ry)) in enumerate(pomdp.rocks_positions)
        ctx = cell_ctx((rx, ry), (nx, ny))
        clr = "black"
        if viz_rock_state && get(step, :s, nothing) !== nothing
            clr = step[:s].rocks[i] ? "green" : "red"
        end
        rock = compose(ctx, ngon(0.5, 0.5, 0.3, 6), stroke(clr), fill("gray"))
        push!(rocks, rock)
    end
    rocks = compose(context(), rocks...)

    exit_area = render_exit((nx, ny), pomdp.final_pos)
    start_area = render_start((nx,ny), pomdp.init_pos)

    agent = nothing
    action = nothing
    if get(step, :s, nothing) !== nothing
        agent_ctx = cell_ctx(step[:s].pos, (nx, ny))
        agent = render_agent(agent_ctx)
        if get(step, :a, nothing) !== nothing
            action = render_action(pomdp, step)
        end
    end
    action_text = render_action_text(pomdp, step, pre_act_text)

    belief = nothing
    #if viz_belief && (get(step, :b, nothing) !== nothing)
    #    belief = render_belief(pomdp, step)
    #end
    sz = min(w, h)
    return compose(context((w - sz) / 2, (h - sz) / 2, sz, sz), action, agent, belief,
        exit_area, start_area, rocks, action_text, grid, outline)
end

function cell_ctx(xy, size)
    nx, ny = size
    x, y = xy
    return context((x - 1) / nx, (ny - y - 1) / ny, 1 / nx, 1 / ny)
end

function render_belief(pomdp::RockSamplePOMDP, step)
    rock_beliefs = get_rock_beliefs(pomdp, get(step, :b, nothing))
    nx, ny = pomdp.map_size[1], pomdp.map_size[2]
    belief_outlines = []
    belief_fills = []
    for (i, (rx, ry)) in enumerate(pomdp.rocks_positions)
        ctx = cell_ctx((rx, ry), (nx, ny))
        clr = "black"
        belief_outline = compose(ctx, rectangle(0.1, 0.87, 0.8, 0.07), stroke("gray31"), fill("gray31"))
        #belief_fill = compose(ctx, rectangle(0.1, 0.87, rock_beliefs[i] * 0.8, 0.07), stroke("lawngreen"), fill("lawngreen"))
        push!(belief_outlines, belief_outline)
        #push!(belief_fills, belief_fill)
    end
    return compose(context(), belief_outlines...)
end

function get_rock_beliefs(pomdp::RockSamplePOMDP{K}, b) where K
    rock_beliefs = zeros(Float64, K)
    for (sᵢ, bᵢ) in weighted_iterator(b)
        rock_beliefs[sᵢ.rocks.==1] .+= bᵢ
    end
    return rock_beliefs
end

function render_exit(size, final_pos::RSPos)
    nx, ny = size
    ctx = cell_ctx((final_pos[1], final_pos[2]), (nx, ny))
    return compose(ctx, rectangle(), fill("red"))
end

function render_start(size, pos::RSPos)
    nx, ny = size
    ctx = cell_ctx((pos[1], pos[2]), (nx, ny))
    return compose(ctx, rectangle(), fill("green"))
end

function render_agent(ctx)
    center = compose(context(), circle(0.5, 0.5, 0.3), fill("orange"), stroke("black"))
    lwheel = compose(context(), ellipse(0.2, 0.5, 0.1, 0.3), fill("orange"), stroke("black"))
    rwheel = compose(context(), ellipse(0.8, 0.5, 0.1, 0.3), fill("orange"), stroke("black"))
    return compose(ctx, center, lwheel, rwheel)
end

function render_action_text(pomdp::RockSamplePOMDP, step, pre_act_text)    
    actions = ["MapCheck", "North", "NorthEast", "East", "SouthEast","South","SouthWest","West","NorthWest"]
    action_text = "Terminal"
    if get(step, :a, nothing) !== nothing
        if step.a <= N_BASIC_ACTIONS
            action_text = actions[step.a]
        else
            action_text = "Sensing Rock $(step.a - N_BASIC_ACTIONS)"
        end
    end
    action_text = pre_act_text * action_text

    _, ny = pomdp.map_size
    ny += 1
    ctx = context(0, (ny - 1) / ny, 1, 1 / ny)
    txt = compose(ctx, text(0.5, 0.5, action_text, hcenter),
        stroke("black"),
        fill("black"),
        fontsize(20pt))
    return compose(ctx, txt, rectangle(), fill("white"))
end

function render_action(pomdp::RockSamplePOMDP, step)
    if step.a == BASIC_ACTIONS_DICT[:sample]
        ctx = cell_ctx(step.s.pos, pomdp.map_size .+ (0, 1))
        if in(step.s.pos, pomdp.rocks_positions)
            rock_ind = findfirst(isequal(step.s.pos), pomdp.rocks_positions)
            clr = step.s.rocks[rock_ind] ? "green" : "red"
            println("rock state is:", rock_ind, clr)
        else
            clr = "black"
        end
        return compose(ctx, ngon(0.5, 0.5, 0.1, 6), stroke("gray"), fill(clr))
    elseif step.a > N_BASIC_ACTIONS
        rock_ind = step.a - N_BASIC_ACTIONS
        rock_pos = pomdp.rocks_positions[rock_ind]
        nx, ny = pomdp.map_size[1], pomdp.map_size[2] + 1
        rock_pos = ((rock_pos[1] - 0.5) / nx, (ny - rock_pos[2] - 0.5) / ny)
        rob_pos = ((step.s.pos[1] - 0.5) / nx, (ny - step.s.pos[2] - 0.5) / ny)
        sz = min(w, h)
        return compose(context((w - sz) / 2, (h - sz) / 2, sz, sz), line([rob_pos, rock_pos]), stroke("orange"), linewidth(0.01w))
    end
    return nothing
end
